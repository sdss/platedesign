#!/usr/bin/env python
# encoding: utf-8
#
# plate_plans_db.py
#
# Originally created by Demitri Muna in 2004
# Rewritten by José Sánchez-Gallego on 14 Jun 2017.


from __future__ import division
from __future__ import print_function
from __future__ import absolute_import

import hashlib
import os
import six
import warnings

import peewee

from astropy import table

from platedesign.core.logger import get_log
from platedesign import utils

from .populate_obs_ranges import populate_obs_range
from .plate_holes_db import plate_holes_db
from .plate_addenda_db import plate_addenda_db

from sdssdb.observatory import platedb

import numpy as np


@platedb.database.atomic()
def _load_design(design_id, log, overwrite=False):
    """Loads a design into the DB."""

    design_dbo, created = platedb.Design.get_or_create(pk=design_id)

    if not created:
        log.info('found design {0} in the DB.'.format(design_id))
        if overwrite:
            warnings.warn('overwriting design for design_id={0}.'.format(design_id),
                          UserWarning)
        else:
            return
    else:
        log.info('creating new Design for design_id={0}.'.format(design_id))

    definition = utils.definition_from_id(design_id)

    # Delete old values (if present; easier than syncing).
    for xx in design_dbo.values:
        xx.delete_instance()

    for key in definition.keys():

        design_value_dbo = platedb.DesignValue()
        design_value_dbo.design = design_dbo
        design_value_dbo.value = definition[key]

        design_field_dbo, created = platedb.DesignField.get_or_create(label=key)
        if created:
            log.debug('created new row in DesignField with value label={0!r}'.format(key))

        design_value_dbo.field = design_field_dbo

        design_value_dbo.save()

    # Handle inputs (PlateInput)

    # Delete any old inputs if present.
    for xx in design_dbo.inputs:
        xx.delete_instance()

    priority_list = 'priority' in definition and list(map(int, definition['priority'].split()))

    for key in definition:
        if not key.startswith('plateinput'):
            continue
        input_number = int(key.strip('plateinput'))
        priority = priority_list[input_number - 1] if priority_list else None
        filepath = definition[key]

        plate_input_dbo = platedb.PlateInput()
        plate_input_dbo.design = design_dbo
        plate_input_dbo.input_number = input_number
        plate_input_dbo.priority = priority
        plate_input_dbo.filepath = filepath

        plate_input_full_path = os.path.join(os.environ['PLATELIST_DIR'], 'inputs', filepath)

        if not os.path.exists(plate_input_full_path):
            warnings.warn('cannot find plateInput {0}. '
                          'MD5 check sum will be null.'.format(filepath), UserWarning)
        else:
            plate_input_dbo.md5_checksum = hashlib.md5(
                open(plate_input_full_path).read().encode('utf-8')).hexdigest()

        log.debug('added plateInput file {0}'.format(filepath))
        plate_input_dbo.save()

    # Create Pointings
    no_pointings = int(definition['npointings'])

    # If the design already has pointings it must be because we are loading a
    # plate from a design already loaded. In that case we check that the number
    # of pointings loaded matches.
    if len(design_dbo.pointings) > 0 and len(design_dbo.pointings) != no_pointings:
        # If the number of pointins disagree but they do not have plate_pointings
        # associated, we can remove the pointings and start from scratch.
        no_plate_pointings = np.sum([len(pointing.plate_pointings)
                                     for pointing in design_dbo.pointings])

        if no_plate_pointings > 0:
            raise RuntimeError('design_id {0} has pointins with '
                               'already created plate_pointings. '
                               'This requires manual intervention.'
                               .format(design_id))
        else:
            for pointing_dbo in design_dbo.pointings:
                pointing_dbo.delete_instance()

    for pno in range(1, no_pointings + 1):
        pointing_dbo, created = platedb.Pointing.get_or_create(design_pk=design_dbo.pk,
                                                               pointing_no=pno)
        pointing_dbo.design = design_dbo
        pointing_dbo.center_ra = definition['racen'].split()[pno - 1]
        pointing_dbo.center_dec = definition['deccen'].split()[pno - 1]
        pointing_dbo.pointing_no = pno

        pointing_dbo.save()

        if created:
            log.debug('created pointing #{0} for design {1}'.format(pno, design_id))
        else:
            log.info('found pointing #{0} for design {1} in DB'.format(pno, design_id))


@platedb.database.atomic()
def _load_plate(plate_id, plateplans_line, log, overwrite=False):
    """Loads a plate and plate_pointing infor to the DB."""

    # Does this plate exist in the database?
    plate_dbo, created = platedb.Plate.get_or_create(plate_id=plate_id)

    if not created:
        log.info('found plate {0} in the DB.'.format(plate_id))
        if overwrite:
            warnings.warn('overwriting plate for plate_id={0}.'.format(plate_id),
                          UserWarning)
        else:
            return
    else:
        log.info('creating new Plate for plate_id={0}.'.format(plate_id))

    plate_dbo.plate_id = plateplans_line['plateid']
    plate_dbo.location_id = plateplans_line['locationid']
    plate_dbo.temperature = plateplans_line['temp']
    plate_dbo.epoch = plateplans_line['epoch']
    plate_dbo.center_ra = plateplans_line['raCen']
    plate_dbo.center_dec = plateplans_line['decCen']
    plate_dbo.rerun = plateplans_line['rerun']
    plate_dbo.chunk = plateplans_line['chunk']

    if plateplans_line['name'] != "''" and len(plateplans_line['name']) > 0:
        plate_dbo.name = plateplans_line['name']

    plate_dbo.comment = plateplans_line['comments']

    # Tile info
    tileid = plateplans_line['tileid']
    if tileid > -1:
        plate_dbo.tile_id = tileid
        tile_dbo, created = platedb.Tile.get_or_create(id=tileid)
        if not created:
            log.debug('found tile {0} in the DB'.format(tileid))
        else:
            log.debug('created new tile with id={0}'.format(tileid))

        tile_dbo.save()

        plate_dbo.tile = tile_dbo

    plate_dbo.epoch = round(plateplans_line['epoch'], 6)
    plate_dbo.center_ra = round(plateplans_line['raCen'], 6)
    plate_dbo.center_dec = round(plateplans_line['decCen'], 6)

    # Assigns the platerun
    try:
        platerun_dbo = platedb.PlateRun.get(label=plateplans_line['platerun'])
    except peewee.DoesNotExist:
        raise ValueError('cannot found a PlateRun row for plate {0}. '
                         'The design should already be in the DB.'.format(plate_id))

    plate_dbo.plate_run = platerun_dbo

    # Sets the plate status to design.
    design_status = platedb.PlateStatus.get(label='Design')
    plate_dbo.statuses.clear()  # First remove statuses
    plate_dbo.statuses.add([design_status])

    # Handle survey relationship
    plate_dbo.surveys.clear()  # First remove surveys
    for survey in six.u(plateplans_line['survey']).split('-'):
        plate_dbo.surveys.add([platedb.Survey.get(plateplan_name=survey)])

    # Ensure "design" foreign key constraint is met (lookup design from db).
    design_id = plateplans_line['designid']
    try:
        # Look for existing design in the database.
        design_dbo = platedb.Design.get(pk=design_id)
        log.debug('found design {0} for plate {1}.'.format(design_id, plate_id))
    except peewee.DoesNotExist:
        raise ValueError('cannot found a Design for plate {0}. '
                         'The design should already be in the DB.'.format(plate_id))

    plate_dbo.design = design_dbo

    # The default survey mode key needs to also be written to the plate table
    defaultsurveymode_dbo = platedb.DesignValue.select().join(
        platedb.DesignField).where((platedb.DesignValue.design_pk == design_dbo.pk) &
                                   (platedb.DesignField.label == 'defaultsurveymode'))

    if len(defaultsurveymode_dbo) == 0:
        warnings.warn('cannot find defaultsurveymode for '
                      'design {0} for plate {1}. '
                      'Not setting current_survey_mode'.format(design_dbo.pk, plate_id))
    else:
        defaultsurveymode = defaultsurveymode_dbo[0].value

        survey_mode_pk = platedb.SurveyMode.select(platedb.SurveyMode.pk).where(
            platedb.SurveyMode.definition_label ** defaultsurveymode).scalar()

        if not survey_mode_pk:
            raise RuntimeError('The database is missing an entry in \'survey_mode\' '
                               'for the entry {0!r}.'.format(defaultsurveymode))

        plate_dbo.current_survey_mode_pk = survey_mode_pk

    plate_dbo.save()

    # PlatePointings
    # The actual instance of a telescope pointing - the parameters of Pointing
    # plus an actual plate and hour angle.

    for pointing_dbo in plate_dbo.design.pointings:

        plate_pointing_dbo, created = platedb.PlatePointing.get_or_create(
            pointing_pk=pointing_dbo.pk, plate_pk=plate_dbo.pk,
            defaults={'pointing_name': 'A'})

        if not created:
            log.debug('found plate_pointing for plate_id={0} in DB.'.format(plate_id))
            return

        pno = pointing_dbo.pointing_no

        plate_pointing_dbo.design = design_dbo
        plate_pointing_dbo.pointing = pointing_dbo
        plate_pointing_dbo.plate = plate_dbo
        plate_pointing_dbo.hour_angle = plateplans_line['ha'][pno - 1]

        pointing_name = platedb.DesignValue.select().join(
            platedb.DesignField).where((platedb.DesignValue.design_pk == design_dbo.pk) &
                                       (platedb.DesignField.label == 'pointing_name'))

        if len(pointing_name) == 0:
            raise ValueError('cannot find pointing_name for '
                             'design {0} for plate {1}'.format(design_dbo.pk, plate_id))

        plate_pointing_dbo.pointing_name = pointing_name[0].value.split()[pno - 1]

        # Sets the priority to 5 for MaNGA and APOGEE, 2 for eBOSS
        survey = six.u(plateplans_line['survey'])
        if 'manga' in survey or 'apogee' in survey:
            plate_pointing_dbo.priority = 5
        else:
            plate_pointing_dbo.priority = 2

        plate_pointing_dbo.save()
        log.debug('created plate_pointing {0} for plate_id={1}.'
                  .format(plate_pointing_dbo.pointing_name, plate_id))


def plate_plans_db(inputs, plate_mode=False, verbose=False, overwrite=False,
                   log=None, load_holes=True, load_addenda=True):
    """Loads plateruns or plates from platePlans into the DB.

    Parameters:
        inputs (list, tuple):
            A list of plateruns or plates to be ingested into the DB.
        plate_mode (bool):
            If ``True``, treats ``inputs`` as a list of plates.
            Otherwise assumes they are plateruns.
        verbose (bool):
            If ``True`` outputs more information in the shell log.
        overwrite (bool):
            If ``True``, values in the DB will be overwritten if needed.
        log (``platedesign.core.logger.Logger`` object):
            A ``Logger`` object to use. Otherwise it will create a new log.
        load_holes (bool):
            If ``True``, loads the plateHoles file along with the plate.
        load_addenda (bool):
            If ``True``, loads the plateDefinitionAddenda file along with the design.

    """

    if not log:
        log = get_log(log_level='INFO' if not verbose else 'DEBUG')

    log.info('running plate_plans_db in mode={0!r}.'.format('platerun'
                                                            if not plate_mode else 'plate'))

    # Checks the connection
    conn_status = platedb.database.check_connection()
    if conn_status:
        log.info('database connection is open.')
    else:
        raise RuntimeError('cannot connect to the database. Review you connection settings.')

    # Creates a list of platePlans lines for each platerun and plate.
    # Converts the lines to an astropy table for easier handling.
    lines_dict = {}
    if not plate_mode:
        for platerun in inputs:
            lines = utils.get_lines_for_platerun(platerun)
            if len(lines) == 0:
                raise ValueError('no platePlans lines found for platerun {0!r}'.format(platerun))
            lines_dict[platerun] = table.Table(lines)
    else:
        for plate in inputs:
            line = utils.get_lines_for_plate(plate)
            if len(line) == 0:
                raise ValueError('cannot find platePlans line for plate {0!r}'.format(plate))
            platerun = line[0]['platerun']
            if platerun not in lines_dict:
                lines_dict[platerun] = table.Table(line)
            else:
                lines_dict[platerun].add_row(line[0])

    if len(lines_dict) == 0:
        raise ValueError('no plateruns found. Your input parameters '
                         'do not seem to match any plate.')

    # Check for valid "survey" values.
    # Joint surveys are separated by a hyphen, e.g. "apogee-marvels".
    # These should be split so that the literal string is not added as a new survey.
    unique_surveys = set()
    for platerun in lines_dict:
        for survey in lines_dict[platerun]['survey'].astype('U'):
            for xx in survey.split('-'):
                unique_surveys.add(xx)

    # Checks surveys
    for survey in unique_surveys:
        try:
            platedb.Survey.get(platedb.Survey.plateplan_name == survey)
            log.debug('survey {0!r} is in the DB'.format(survey))
        except peewee.DoesNotExist:
            raise ValueError('A survey name was found that does not appear in the database: {0!r}'
                             'Please correct the platePlans.par entry or else add the new survey '
                             'to the survey table in the plate database.'.format(survey))

    for platerun in lines_dict:

        run_lines = lines_dict[platerun]

        log.important('now doing platerun {0!r} ...'.format(platerun))

        # Populate plate_run table if a new value is found.
        try:
            year = int(platerun[0:4])
        except ValueError:
            warnings.warn('Could not determine the year for platerun {0!r}; '
                          'please update this value in the plate_run table by hand.'
                          .format(platerun), UserWarning)

        pr, created = platedb.PlateRun.get_or_create(label=platerun, year=year)

        if not created:
            log.debug('platerun {0} already is already in the DB.'.format(platerun))
        else:
            log.debug('added platerun {0} to the plate_run table.'.format(platerun))

        design_ids = np.unique(run_lines['designid'])

        for design_id in design_ids:

            log.important('loading design_id={0}'.format(design_id))
            _load_design(design_id, log, overwrite=overwrite)

        if load_addenda:
            log.important('loading plateDefinitionAddendas ...')
            plate_addenda_db(design_ids, design_mode=True, log=log)

        plate_ids = np.unique(run_lines['plateid'])

        for plate_id in plate_ids:

            plate_line = run_lines[run_lines['plateid'] == plate_id][0]

            log.important('loading plate_id={0}'.format(plate_id))
            _load_plate(plate_id, plate_line, log, overwrite=overwrite)

        log.important('populating observing ranges for {0} ... '.format(platerun))
        populate_obs_range(plate_ids, log=log)

        if load_holes:
            log.important('loading plate holes for {0} ...'.format(platerun))
            plate_holes_db(plate_ids, plate_mode=True, log=log, overwrite=overwrite)

    log.important('success! All designs and plates have been loaded.')

#!/usr/bin/env python
# encoding: utf-8
#
# plate_holes_db.py
#
# Originally created by Demitri Muna
# Rewritten by José Sánchez-Gallego in Jun 2017.


from __future__ import division
from __future__ import print_function
from __future__ import absolute_import

import os
import warnings

import peewee

from platedesign.core.logger import get_log
from platedesign import utils

from sdssdb.peewee.operationsdb import platedb

from sdss.utilities import yanny


def plate_holes_db(inputs, plate_mode=False, verbose=False, overwrite=False, log=None):
    """Loads plateruns or plates from plateHoles into the DB.

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

    """

    if not log:
        log = get_log(log_level='INFO' if not verbose else 'DEBUG')

    log.info('running plate_holes_db in mode={0!r}.'.format('platerun'
                                                            if not plate_mode else 'plate'))

    # Checks the connection
    conn_status = platedb.database.check_connection()
    if conn_status:
        log.info('database connection is open.')
    else:
        raise RuntimeError('cannot connect to the database. Review you connection settings.')

    # Creates a list of plates for each platerun and plate.
    plates = []
    if not plate_mode:
        for platerun in inputs:
            lines = utils.get_lines_for_platerun(platerun)
            if len(lines) == 0:
                raise ValueError('no platePlans lines found for platerun {0!r}'.format(platerun))
            plates += lines['plateid'].tolist()
    else:
        plates = inputs

    if len(plates) == 0:
        raise ValueError('no plates found. Your input parameters '
                         'do not seem to match any plate.')

    log.info('loading plateHoles for {0} plates.'.format(len(plates)))

    with platedb.database.atomic():

        for plate_id in plates:

            plate_holes_path = utils.get_path('plateHoles', plateid=plate_id)
            plate_holes_filename = os.path.basename(plate_holes_path)

            assert os.path.exists(plate_holes_path), \
                'cannot find file {0}'.format(plate_holes_path)

            plate_holes = yanny.yanny(plate_holes_path, np=True)['STRUCT1']

            log.debug('loaded file {0}.'.format(plate_holes_filename))

            try:
                plate_dbo = platedb.Plate.get(plate_id=plate_id)
            except peewee.DoesNotExist:
                raise ValueError('Could not find plate {0} in the database. '
                                 'Has the plate been added?'.format(plate_id))

            # Populate the plate_holes_file table.
            phf_dbo, created = platedb.PlateHolesFile.get_or_create(
                filename=plate_holes_filename, plate_pk=plate_dbo.pk)

            if not created:
                log.debug('plateHoles file for plate {0} already in the database.'
                          .format(plate_id))
            else:
                log.debug('created PlateHolesFile for plate {0}'.format(plate_id))

            if created or overwrite:
                phf_dbo.save()

            if len(phf_dbo.plate_holes) > 0:
                if not overwrite:
                    log.debug('found plate holes already in the DB for plate {0}. '
                              'Skipping this plate.'.format(plate_id))
                    continue
                else:
                    warnings.warn('found plate holes in the DB for plate {0}. '
                                  'Overwriting.'.format(plate_id), UserWarning)

            log.debug('removing any previous plate holes for plate {0}'.format(plate_id))
            ph_delete = platedb.PlateHole.delete().where(
                platedb.PlateHole.plate_holes_file_pk == phf_dbo.pk)
            ph_delete.execute()

            nn = 0
            for plate_hole in plate_holes:

                ph_dbo = platedb.PlateHole()
                ph_dbo.plate_holes_file = phf_dbo
                ph_dbo.xfocal = plate_hole['xfocal']
                ph_dbo.yfocal = plate_hole['yfocal']
                ph_dbo.tmass_h = plate_hole['tmass_h']
                ph_dbo.tmass_j = plate_hole['tmass_j']
                ph_dbo.tmass_k = plate_hole['tmass_k']
                ph_dbo.pointing_number = plate_hole['pointing']
                ph_dbo.apogee_target1 = plate_hole['apogee2_target1'] \
                    if 'apogee2_target1' in plate_hole.dtype.names else None
                ph_dbo.apogee_target2 = plate_hole['apogee2_target2'] \
                    if 'apogee2_target2' in plate_hole.dtype.names else None

                # Populate the rest of the plate_hole table from queries.
                try:
                    pht_dbo = platedb.PlateHoleType.get(label=plate_hole['holetype'])
                    ph_dbo.plate_hole_type = pht_dbo
                except peewee.DoesNotExist:
                    raise RuntimeError('PlateHoleType {0!r} does not appear to exist in the DB.'
                                       'Add it to the PlateHoleType table manually and load '
                                       'this plate again.'.format(plate_hole['holetype']))

                try:
                    ot_dbo = platedb.ObjectType.get(label=plate_hole['targettype'])
                    ph_dbo.objectType = ot_dbo
                except peewee.DoesNotExist:
                    raise RuntimeError('ObjectType {0!r} does not appear to exist in the DB.'
                                       'Add it to the ObjectType table manually and load '
                                       'this plate again.'.format(plate_hole['targettype']))
                nn += 1

                ph_dbo.save()

            log.info('loaded {0} plateHoles for plate {1}'.format(nn, plate_id))

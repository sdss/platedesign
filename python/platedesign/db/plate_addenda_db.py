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


def plate_addenda_db(inputs, design_mode=False, verbose=False, log=None):
    """Loads plateDefinitionAddendas to the DB from plateruns or designs.

    Parameters:
        inputs (list, tuple):
            A list of plateruns or plates to be ingested into the DB.
        design_mode (bool):
            If ``True``, treats ``inputs`` as a list of design ids.
            Otherwise assumes they are plateruns.
        verbose (bool):
            If ``True`` outputs more information in the shell log.
        log (``platedesign.core.logger.Logger`` object):
            A ``Logger`` object to use. Otherwise it will create a new log.

    """

    if not log:
        log = get_log(log_level='INFO' if not verbose else 'DEBUG')

    log.info('running plate_addenda_db in mode={0!r}.'.format('platerun'
                                                              if not design_mode else 'plate'))

    # Checks the connection
    conn_status = platedb.database.check_connection()
    if conn_status:
        log.info('database connection is open.')
    else:
        raise RuntimeError('cannot connect to the database. Review you connection settings.')

    # Creates a list of plates for each platerun and plate.
    designs = []
    if not design_mode:
        for platerun in inputs:
            lines = utils.get_lines_for_platerun(platerun)
            if len(lines) == 0:
                raise ValueError('no platePlans lines found for platerun {0!r}'.format(platerun))
            designs += lines['designid'].tolist()
    else:
        designs = inputs

    if len(designs) == 0:
        raise ValueError('no designs found. Your input parameters '
                         'do not seem to match any plate.')

    log.info('loading plateDefinitionAddenda for {0} designs.'.format(len(designs)))

    with platedb.database.atomic():

        for design_id in designs:

            log.info('loading plateDefinitionAddenda for design {0}'.format(design_id))

            plate_definition_path = utils.get_path('plateDefinitionAddenda', designid=design_id)

            if not os.path.exists(plate_definition_path):
                warnings.warn('cannot find a plateDefinitionAddenda '
                              'for design {0}. Skipping it.'.format(design_id), UserWarning)
                continue

            definition = yanny.yanny(plate_definition_path)
            definition_lower = dict((kk.lower(), vv)
                                    for kk, vv in definition.items() if kk != 'symbols')

            # Fetch design
            try:
                design_dbo = platedb.Design.get(pk=design_id)
            except peewee.DoesNotExist:
                raise RuntimeError('the design {0} cannot be found in the DB. '
                                   'Make sure you have loaded it first.'.format(design_id))

            for key in definition_lower:

                field_name = key
                value = definition_lower[key]

                # Gets or creates the field object

                design_field_dbo, created = platedb.DesignField.get_or_create(label=field_name)

                if created:
                    warnings.warn('design_id={0}: the design field {1} was not found. Adding it.'
                                  .format(design_id, field_name), UserWarning)

                # Check if there is an existing value with this key
                design_value_dbo = platedb.DesignValue.select().where(
                    platedb.DesignValue.design_pk == design_dbo.pk,
                    platedb.DesignValue.design_field_pk == design_field_dbo.pk).first()

                if design_value_dbo is None:
                    # Create a new value
                    design_value_dbo = platedb.DesignValue()
                    design_value_dbo.design_field_pk = design_field_dbo.pk
                    design_value_dbo.design_pk = design_dbo.pk
                    log.debug('design_id={0}: adding new (field, value)=({1!r}, {2!r}).'
                              .format(design_id, design_value_dbo.field.label, value))

                # Updates the value from the plateDefinitionAddenda value
                design_value_dbo.value = value

                design_field_dbo.save()
                design_value_dbo.save()

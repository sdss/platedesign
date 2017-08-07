#!/usr/bin/env python
# encoding: utf-8
#
# populate_obs_range.py
#
# Originally created by Demitri Muna
# Rewritten by José Sánchez-Gallego in Jun 2017.


from __future__ import division
from __future__ import print_function
from __future__ import absolute_import

import os
import warnings

import numpy as np

import astropy.table as table

from sdssdb.observatory import platedb

from sdss.utilities import yanny

from platedesign.core.logger import get_log
from platedesign import utils


exceptions_file = os.path.join(os.environ['PLATELIST_DIR'], 'etc',
                               'observing_range_exceptions.txt')

assert os.path.exists(exceptions_file), 'cannot find observing_range_exceptions.txt'

never_drilled_file = os.path.join(os.environ['PLATELIST_DIR'], 'etc',
                                  'plates_never_drilled.dat')

assert os.path.exists(never_drilled_file), 'cannot find plates_never_drilled.dat'

exceptions = table.Table.read(exceptions_file, format='ascii',
                              names=['plateid', 'ha_observable_min',
                                     'ha_observable_max'])

never_drilled = []
for line in open(never_drilled_file, 'r').read().splitlines():
    line_strip = line.strip()
    if line_strip.startswith('#') or line_strip == '':
        continue
    if '-' in line_strip:
        begin, end = line_strip.split('-')
        never_drilled += list(range(int(begin), int(end) + 1))
    else:
        never_drilled.append(int(line_strip))


def populate_all(**kwargs):
    """Reloads the observing ranges for all the plates in platePlans.

    Parameters:
        kwargs (dict):
            Parameters to be passed to ``populate_obs_range``.

    """

    platePlans = utils.get_platePlans()

    return populate_obs_range(platePlans['plateid'], **kwargs)


def populate_obs_range(plates, verbose=False, log=None, ignore_missing=False):
    """Loads observing ranges into the DB.

    Parameters:
        plates (list, tuple):
            A list of plates for which to load or update the observing ranges.
        verbose (bool):
            If ``True`` outputs more information in the shell log.
        log (``platedesign.core.logger.Logger`` object):
            A ``Logger`` object to use. Otherwise it will create a new log.
        ignore_missing (bool):
            If ``True``, does not fail if a PlatePointing object cannot be
            found for the plate.

    """

    if not log:
        log = get_log(log_level='INFO' if not verbose else 'DEBUG')

    # Checks the connection
    conn_status = platedb.database.check_connection()
    if conn_status:
        log.debug('database connection is open.')
    else:
        raise RuntimeError('cannot connect to the database. Review you connection settings.')

    # values we want to read
    keys_to_read = ['ha_observable_min',
                    'ha_observable_max',
                    'npointings',
                    'pointing_name']

    with platedb.database.atomic():

        for plate_id in sorted(plates):

            log.info('loading observing ranges for plate {0}.'.format(plate_id))

            pl_plugmap_p = utils.get_path('plPlugMapP', plateid=plate_id)

            assert os.path.exists(pl_plugmap_p), 'cannot find file {0}'.format(pl_plugmap_p)

            plugmap = yanny.yanny(pl_plugmap_p)

            for key in keys_to_read:
                assert key in plugmap, 'cannot find key {0} in {1}'.format(key, pl_plugmap_p)

            # determine the pointing number
            if int(plugmap['npointings']) == 1:
                pno = 1
            else:
                warnings.warn('skipping plate {0} that '
                              'has multiple pointings.'.format(plate_id), UserWarning)
                continue

            # select the correct value from the list
            ha_observable_min = float(plugmap['ha_observable_min'].split()[pno - 1])
            ha_observable_max = float(plugmap['ha_observable_max'].split()[pno - 1])

            # Fetch the plate_pointing object
            plate_pointing_dbo = platedb.PlatePointing.select().join(
                platedb.Plate).switch(platedb.PlatePointing).join(platedb.Pointing).where(
                    platedb.Plate.plate_id == plate_id, platedb.Pointing.pointing_no == pno)

            if plate_pointing_dbo.count() == 0:
                if not ignore_missing:
                    raise RuntimeError('Could not find PlatePointing for plate {0}. '
                                       'Has this been loaded into the db?'.format(plate_id))
                else:
                    continue
            elif plate_pointing_dbo.count() > 1:
                raise RuntimeError('Multiple plate pointings '
                                   'found for plate_id {0}'.format(plate_id))

            plate_pointing_dbo = plate_pointing_dbo.first()

            if np.any(exceptions['plateid'] == plate_id):
                warnings.warn('plate {0}: override value used.'.format(plate_id), UserWarning)
                row = exceptions[exceptions['plateid'] == plate_id][0]
                plate_pointing_dbo.ha_observable_min = row['ha_observable_min']
                plate_pointing_dbo.ha_observable_max = row['ha_observable_max']
            else:
                plate_pointing_dbo.ha_observable_min = ha_observable_min
                plate_pointing_dbo.ha_observable_max = ha_observable_max

            plate_pointing_dbo.save()

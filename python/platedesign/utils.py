#!/usr/bin/env python
# encoding: utf-8
#
# utils.py
#
# Created by José Sánchez-Gallego on 14 Jun 2017.


from __future__ import division
from __future__ import print_function
from __future__ import absolute_import

import os

from sdss_access.path import Path
from sdss.utilities import yanny


PLATE_PLANS = None


def get_path(path_id, **kwargs):
    """A wrapper around sdss_access.path.Path."""

    return Path().full(path_id, **kwargs)


def get_platePlans(reload=False):
    """Returns a (cached) copy of platePlans."""

    global PLATE_PLANS

    if PLATE_PLANS is None or reload:
        PLATE_PLANS = yanny.yanny(get_path('platePlans'), np=True)['PLATEPLANS']

    return PLATE_PLANS


def get_lines_for_platerun(platerun):
    """Returns a list of platePlans lines for a platerun."""

    platePlans = get_platePlans()

    return platePlans[platePlans['platerun'].astype('U') == platerun.strip()]


def get_lines_for_plate(plate):
    """Returns the platePlans line for a plateid."""

    platePlans = get_platePlans()

    return platePlans[platePlans['plateid'] == int(plate)]


def get_design_for_plate(plate):
    """Returns the designid for a plate."""

    return get_lines_for_plate(plate)['designid'][0]


def definition_from_id(def_id):
    """Returns a custom dictionary merging the defaults file with plateDefinition."""

    if def_id == -1:
        raise ValueError('SDSS I/II plates don\'t have definition files.')

    custom_defs_file = get_path('plateDefinition', designid=def_id)

    if not custom_defs_file or not os.path.exists(custom_defs_file):
        raise ValueError('cannot find plateDefinition file for design_id={0}.'.format(def_id))

    custom_defs = yanny.yanny(custom_defs_file)
    # Lowercases and removes symbols
    custom_defs_lower = dict((kk.lower(), vv) for kk, vv in custom_defs.items() if kk != 'symbols')

    # Gets defaults file
    assert 'platetype' in custom_defs_lower, \
        '\'platetype\' not defined in {0!r}'.format(custom_defs_file)
    assert 'platedesignversion' in custom_defs_lower, \
        '\'platedesignversion\' not defined in {0!r}'.format(custom_defs_file)

    defaults_file = get_path('plateDefault',
                             type=custom_defs_lower['platetype'],
                             version=custom_defs_lower['platedesignversion'])

    if not defaults_file or not os.path.exists(defaults_file):
        raise ValueError('cannot find plateDefaults file matching design_id={0}.'.format(def_id))

    definition = yanny.yanny(defaults_file)
    definition_lower = dict((kk.lower(), vv)
                            for kk, vv in definition.items() if kk != 'symbols')

    # Overrrides custom values in defaults
    definition_lower.update(custom_defs_lower)

    return definition_lower

from platedesign.survey.APOGEE2 import apogee_south_blocks
from pyx import document, color, path, canvas, style, text, deco, trafo
from scipy.spatial import Voronoi
import pydl.pydlutils.yanny as yanny
from sdss_access import SDSSPath
import numpy as np
import os.path
import re
import sys

limit_radius = 41.5
full_radius = 39.7
interior_radius = 32.6  # cm

# acquisition camera settings
center_radius = 3.0
offaxis_xsize = 5.5
offaxis_ysize = 4.0

# sdss_path = sdss_access.path.path()
sdssPath = SDSSPath()


def offset_line(offset_amount, vertex_start, vertex_end, point):
    # Get vector and unit vector along ridge
    distance = vertex_start - vertex_end
    adistance = np.sqrt((distance**2).sum())
    udistance = distance / adistance

    # Get unit vector from one end of ridge to point
    topoint = point - vertex_start

    offset = topoint - (topoint * udistance).sum() * udistance
    aoffset = np.sqrt((offset**2).sum())
    uoffset = offset / aoffset

    return(vertex_start - offset_amount * uoffset,
           vertex_end - offset_amount * uoffset)


def apogee_layer(holes, numbers=False, renumber=False):
    offset_amount = -0.03
    hole_radius = 0.4

    # Read in APOGEE blocks information
    blocks = apogee_south_blocks()

    # Set up colors
    pyxcolor = dict()
    pyxcolor['red'] = color.cmyk.Red
    pyxcolor['black'] = color.cmyk.Black
    pyxcolor['blue'] = color.cmyk.CornflowerBlue

    # Get science fiber information
    isci = np.nonzero(np.array(holes['holetype']) == b'APOGEE_SOUTH')[0]
    xfocal = np.array(holes['xfocal'])[isci]
    yfocal = np.array(holes['yfocal'])[isci]
    fiberid = np.array(holes['fiberid'])[isci]
    block = np.array(holes['block'])[isci]

    if(renumber):
        fiberid = np.array(blocks.fibers['fiberid'])[fiberid - 1]
        block = np.array(blocks.fibers['blockid'])[fiberid - 1]

    # Create Voronoi tessellation
    xy = np.array([xfocal, yfocal]).transpose()
    vor = Voronoi(xy)
    nridges = vor.ridge_points.shape[0]

    # Set up object to print
    clippath= path.circle(0., 0., interior_radius)
    clipobject = canvas.clip(clippath)
    interior=canvas.canvas([clipobject])

    # Print lines separating blocks
    for indx in range(nridges):
        iv0= vor.ridge_vertices[indx][0]
        iv1= vor.ridge_vertices[indx][1]
        ip0= vor.ridge_points[indx][0]
        ip1= vor.ridge_points[indx][1]
        point0= vor.points[ip0,:]/10.
        point1= vor.points[ip1,:]/10.
        ib0= block[ip0]
        ib1= block[ip1]
        if(iv0>0 and iv1>0 and ib0 != ib1):
            if(ib0 <= 25):
                side0= 'Red'
            else:
                side0= 'Blue'
            if(ib1 <= 25):
                side1= 'Red'
            else:
                side1= 'Blue'
            if(side0 == side1):
                if(side0 == 'Red'):
                    color0= color.cmyk.Red
                    color1= color.cmyk.Red
                else:
                    color0= color.cmyk.Blue
                    color1= color.cmyk.Blue
            else:
                color0= color.cmyk.Black
                color1= color.cmyk.Black

            vertex_start= vor.vertices[iv0,:]/10.
            vertex_end= vor.vertices[iv1,:]/10.
            (start0,end0)= offset_line(offset_amount, vertex_start, 
                                       vertex_end, point0)
            interior.stroke(path.line(start0[1], start0[0], 
                                      end0[1], end0[0]),
                            [style.linewidth.THick, color0])
            (start1,end1)= offset_line(offset_amount, vertex_start, 
                                       vertex_end, point1)
            interior.stroke(path.line(start1[1], start1[0], 
                                      end1[1], end1[0]),
                            [style.linewidth.THick, color1])

    # Print circles around holes
    for indx in range(len(xfocal)):
        hole_color = pyxcolor[blocks.fcolor(fiberid[indx])]
        interior.stroke(path.circle(yfocal[indx] / 10., xfocal[indx] / 10.,
                                    hole_radius),
                        [style.linewidth.THick, hole_color])

    if(numbers is True):
        #  Print numbers near holes
        for indx in range(len(xfocal)):
            if(indx <= 150):
                props = [text.halign.boxleft, text.valign.middle]
            else:
                props = [text.halign.boxright, text.valign.middle,
                         trafo.rotate(180.)]
            interior.text((yfocal[indx] / 10.) + hole_radius * 1.2,
                          (xfocal[indx] / 10.),
                          r"\font\myfont=cmr10 at 20pt {\myfont " +
                          str(fiberid[indx]) + "}", props)
    return interior


def guide_layer(holes):
    guide_size = 1.2

    # Get guide fiber information
    iguide = np.nonzero(np.array(holes['holetype']) == b'GUIDE')[0]
    guide_xfocal = np.array(holes['xfocal'])[iguide]
    guide_yfocal = np.array(holes['yfocal'])[iguide]
    guidenum = np.array(holes['iguide'])[iguide]

    # Set up object to print
    clippath = path.circle(0., 0., interior_radius)
    clipobject = canvas.clip(clippath)
    interior = canvas.canvas([clipobject])

    for indx in range(len(guide_xfocal)):
        interior.stroke(path.rect((guide_yfocal[indx] / 10.) -
                                  guide_size * 0.5,
                                  (guide_xfocal[indx] / 10.) -
                                  guide_size * 0.5,
                                  guide_size, guide_size),
                        [style.linewidth.THick, color.cmyk.Black])
        interior.text((guide_yfocal[indx] / 10.) + guide_size * 0.66,
                      (guide_xfocal[indx] / 10.),
                      r"\font\myfont=cmr10 at 35pt {\myfont " +
                      str(guidenum[indx]) + "}",
                      [text.halign.boxleft, text.valign.middle,
                       text.size.Huge])

    return interior


def acquisition_layer(holes):

    # Get camera info
    icenter = np.nonzero(np.array(holes['holetype']) ==
                         b'ACQUISITION_CENTER')[0]
    if(len(icenter) == 0):
        return None
    if(len(icenter) > 1):
        print("Expect just one central acquisition camera.")
    center_xfocal = np.array(holes['xfocal'])[icenter[0]]
    center_yfocal = np.array(holes['yfocal'])[icenter[0]]

    ioffaxis = np.nonzero(np.array(holes['holetype']) == b'ACQUISITION_OFFAXIS')[0]
    if(len(ioffaxis) == 0):
        print("If there is a center acquisition camera we expect an off-axis.")
        sys.exit()
    if(len(ioffaxis) > 1):
        print("Expect just one off-axis acquisition camera.")
        sys.exit()
    offaxis_xfocal = np.array(holes['xfocal'])[ioffaxis[0]]
    offaxis_yfocal = np.array(holes['yfocal'])[ioffaxis[0]]

    # Set up object to print
    clippath = path.circle(0., 0., interior_radius)
    clipobject = canvas.clip(clippath)
    interior = canvas.canvas([clipobject])

    interior.stroke(path.circle(center_yfocal / 10., center_xfocal / 10.,
                                center_radius),
                    [style.linewidth.THick, color.cmyk.Black])

    interior.stroke(path.rect((offaxis_yfocal / 10.) -
                              offaxis_ysize * 0.5,
                              (offaxis_xfocal / 10.) -
                              offaxis_xsize * 0.5,
                              offaxis_ysize, offaxis_xsize),
                    [style.linewidth.THick, color.cmyk.Black])

    return interior


def whiteout_layer(holes):
    whiteout = canvas.canvas()
    for indx in range(len(holes['xfocal'])):
        radius = 0.25
        if(holes['holetype'][indx] == b'GUIDE'):
            radius = 0.54
        if(holes['holetype'][indx] == b'ALIGNMENT'):
            radius = 0.1
        if(holes['holetype'][indx] == b'MANGA'):
            radius = 0.4
        if(holes['holetype'][indx] == b'MANGA_SINGLE'):
            radius = 0.4
        if(holes['holetype'][indx] == b'MANGA_ALIGNMENT'):
            radius = 0.2
        if(holes['holetype'][indx] == b'CENTER'):
            radius = 0.36
        if(holes['holetype'][indx] == b'TRAP'):
            radius = 0.45
        if(holes['holetype'][indx] == b'ACQUISITION_CENTER'):
            radius = 2.9
        whiteout.fill(path.circle(holes['yfocal'][indx] / 10.,
                                  holes['xfocal'][indx] / 10., radius),
                      [color.rgb.white])

    ioffaxis = np.nonzero(np.array(holes['holetype']) ==
                          b'ACQUISITION_OFFAXIS')[0]
    if(len(ioffaxis) == 0):
        return whiteout
    if(len(ioffaxis) > 1):
        print("Expect just one off-axis acquisition camera.")
        sys.exit()
    offaxis_xfocal = np.array(holes['xfocal'])[ioffaxis[0]]
    offaxis_yfocal = np.array(holes['yfocal'])[ioffaxis[0]]
    whiteout.fill(path.rect((offaxis_yfocal / 10.) -
                            offaxis_ysize * 0.49,
                            (offaxis_xfocal / 10.) -
                            offaxis_xsize * 0.49,
                            0.98 * offaxis_ysize, 0.98 * offaxis_xsize),
                  [color.rgb.white])

    return whiteout


def plate_circle_layer(plate, information, message, plate_radius= 32.6):
    outerclip= 39.6
    box_xoffset= 1.
    box_xsize= 4.
    box_ysize= 16.
    text_ybuffer= 0.5
    text_xbuffer= 0.3
    
    clippath= path.circle(0., 0., outerclip)
    plate_clipobject = canvas.clip(clippath)
    plate_circle=canvas.canvas([plate_clipobject])

    plate_circle.stroke(path.circle(0., 0., plate_radius),
                        [style.linewidth.THICk])
    plate_circle.stroke(path.line(-plate_radius+box_xoffset, 
                            -box_ysize*0.5, 
                            -plate_radius+box_xoffset-box_xsize, 
                            -box_ysize*0.5),
                 [style.linewidth.THICk])
    plate_circle.stroke(path.line(-plate_radius+box_xoffset-box_xsize, 
                            -box_ysize*0.5, 
                            -plate_radius+box_xoffset-box_xsize, 
                            box_ysize*0.5),
                 [style.linewidth.THICk])
    plate_circle.stroke(path.line(-plate_radius+box_xoffset, 
                            box_ysize*0.5, 
                            -plate_radius+box_xoffset-box_xsize, 
                            box_ysize*0.5),
                 [style.linewidth.THICk])
    tab_path= path.line(-plate_radius-text_xbuffer, 
                         -box_ysize*0.5+text_ybuffer, 
                         -plate_radius-text_xbuffer, 
                         box_ysize*0.5-text_ybuffer)
    tab_text= r"\font\myfont=cmr10 at 100pt {\myfont "+str(plate)+"}"
    plate_circle.draw(tab_path, [deco.curvedtext(tab_text)])

    information_path= (path.circle(0., 0., plate_radius).
                       transformed(trafo.rotate(90.)))
    plate_circle.draw(information_path, 
                      [deco.curvedtext(information, textattrs=[text.valign.top,
                                                        text.vshift.topzero])])

    message_path= (path.circle(0., 0., plate_radius).
                   transformed(trafo.rotate(-90.)))
    plate_circle.draw(message_path, 
                      [deco.curvedtext(message, textattrs=[text.valign.top,
                                                        text.vshift.topzero])])
    return plate_circle

def outline_layer():
    tab_xsize= 1.3
    tab_ysize= 2.0
    clippath= path.circle(0., 0., limit_radius)
    clipobject = canvas.clip(clippath)
    outline=canvas.canvas([clipobject])
    outline.stroke(path.circle(0., 0., full_radius), 
                   [style.linewidth.thick])
    outline.stroke(path.line(-full_radius, -tab_ysize*0.5, 
                              -full_radius-tab_xsize, -tab_ysize*0.5),
                   [style.linewidth.thick])
    outline.stroke(path.line(- full_radius, tab_ysize * 0.5,
                             - full_radius - tab_xsize, tab_ysize * 0.5),
                   [style.linewidth.thick])
    outline.stroke(path.line(- full_radius - tab_xsize, - tab_ysize * 0.5,
                             - full_radius - tab_xsize, tab_ysize * 0.5),
                   [style.linewidth.thick])
    outline.stroke(path.line(- full_radius - tab_xsize, 0.,
                             - limit_radius, 0.),
                   [style.linewidth.thick])
    return outline


def overlay_print(plateid, numbers=False, noguides=False, renumber=False,
                  rotate180=False):
    '''
    This function returns a plate overlay as a pyx.document object.
    The calling script can determine what to do with it. To print this
    object as a PDF:

    overlay = overlay_print(plateid=12345)
    overlay.writePDFfile(destination_path)
    '''

    # Get the needed files
    plateHolesSorted_file = sdssPath.full('plateHolesSorted', plateid=plateid)
    if not os.path.isfile(plateHolesSorted_file):
        raise IOError("File not found: {0}".format(plateHolesSorted_file))

    platePlans_file = sdssPath.full('platePlans')
    if not os.path.isfile(platePlans_file):
        raise IOError("File not found: {0}".format(platePlans_file))

    # Read in holes data, extract meta data
    holes_yanny = yanny.yanny(plateHolesSorted_file)
    racen = holes_yanny['raCen']
    deccen = holes_yanny['decCen']
    designid = holes_yanny['designid']
    ha = holes_yanny['ha']
    holes = holes_yanny['STRUCT1']

    if(rotate180):
        holes['xfocal'] = - np.array(holes['xfocal'])
        holes['yfocal'] = - np.array(holes['yfocal'])

    # Read in plans
    plans = yanny.yanny(platePlans_file)
    iplan = np.nonzero(np.array(plans['PLATEPLANS']['plateid']) == plateid)[0]
    survey = plans['PLATEPLANS']['survey'][iplan[0]].decode()
    programname = plans['PLATEPLANS']['programname'][iplan[0]].decode()

    # Texify the string
    programname_str = str(programname)
    programname_str = re.sub("_", "\_", programname_str)

    # Create information string
    information = r"\font\myfont=cmr10 at 40pt {\myfont"
    information += " Plate=" + str(plateid) + "; "
    information += "Design=" + str(designid) + "; "
    information += "Survey=" + str(survey) + "; "
    information += "Program=" + str(programname_str) + "; "
    information += "RA=" + str(racen) + "; "
    information += "Dec=" + str(deccen) + "; "
    information += "HA=" + str(np.float32((ha.split())[0])) + "."
    information += "}"

    # Create message
    message = "Una placa para APOGEE Sur"
    message_tex = r"\font\myfont=cmr10 at 40pt {\myfont " + message + "}"

    apogee = apogee_layer(holes, numbers=numbers, renumber=renumber)
    if(noguides is False):
        guide = guide_layer(holes)
    else:
        guide = None
    whiteout = whiteout_layer(holes)
    plate_circle = plate_circle_layer(plateid, information, message_tex)
    outline = outline_layer()  # pyx.canvas object
    acquisition = acquisition_layer(holes)

    outline.insert(apogee)
    if(guide is not None):
        outline.insert(guide)
    outline.insert(plate_circle)
    if(acquisition is not None):
        outline.insert(acquisition)
    outline.insert(whiteout)

    pformat = document.paperformat(limit_radius * 2., limit_radius * 2.)
    final = document.page(outline, paperformat=pformat)

    return document.document(pages=[final])

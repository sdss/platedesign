from platedesign.survey.APOGEE2 import apogee_blocks
from pyx import document, color, path, canvas, style, text, deco, trafo
from scipy.spatial import Voronoi, voronoi_plot_2d
import sdss.utilities.yanny as yanny
from sdss_access import SDSSPath
import numpy as np
import os.path
import re

limit_radius= 41.5
full_radius= 39.7
interior_radius= 32.6 # cm

#sdss_path = sdss_access.path.path()
sdssPath = SDSSPath()

def offset_line(offset_amount, vertex_start, vertex_end, point):
    # Get vector and unit vector along ridge
    distance= vertex_start-vertex_end
    adistance= np.sqrt((distance**2).sum())
    udistance= distance/adistance
    
    # Get unit vector from one end of ridge to point
    topoint= point-vertex_start
    atopoint= np.sqrt((topoint**2).sum())
    utopoint= topoint/atopoint
    
    offset= topoint - (topoint*udistance).sum()*udistance
    aoffset= np.sqrt((offset**2).sum())
    uoffset= offset/aoffset
    
    return (vertex_start-offset_amount*uoffset, 
            vertex_end-offset_amount*uoffset)

def apogee_layer(holes):
    offset_amount=-0.03
    hole_radius= 0.4

    # Read in APOGEE blocks information
    blocks= apogee_blocks()
    
    # Set up colors 
    pyxcolor= dict()
    pyxcolor['red']=color.cmyk.Red
    pyxcolor['green']=color.cmyk.Green
    pyxcolor['blue']=color.cmyk.Blue

    # Get science fiber information
    isci=np.nonzero(np.array(holes['holetype']) == 'APOGEE_SOUTH')[0]
    xfocal= np.array(holes['xfocal'])[isci]
    yfocal= np.array(holes['yfocal'])[isci]
    fiberid= np.array(holes['fiberid'])[isci]
    block= np.array(holes['block'])[isci]

    # Create Voronoi tessellation
    xy= np.array(zip(xfocal, yfocal))
    vor= Voronoi(xy)
    nridges= vor.ridge_points.shape[0]

    # Set up object to print
    clippath= path.circle(0., 0., interior_radius)
    clipobject = canvas.clip(clippath)
    interior=canvas.canvas([clipobject])

    # Print lines separating blocks
    colors=[color.cmyk.Red, color.cmyk.Green, color.cmyk.Blue,
            color.cmyk.Brown, color.cmyk.Yellow]
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
        hole_color= pyxcolor[blocks.fcolor(fiberid[indx])]
        interior.stroke(path.circle(yfocal[indx]/10., xfocal[indx]/10., 
                                    hole_radius), 
                        [style.linewidth.THick, hole_color])

    return interior

def guide_layer(holes):
    guide_size= 1.2

    # Get guide fiber information
    iguide= np.nonzero(np.array(holes['holetype']) == 'GUIDE')[0]
    guide_xfocal= np.array(holes['xfocal'])[iguide]
    guide_yfocal= np.array(holes['yfocal'])[iguide]
    guidenum= np.array(holes['iguide'])[iguide]
    
    # Set up object to print
    clippath= path.circle(0., 0., interior_radius)
    clipobject = canvas.clip(clippath)
    interior=canvas.canvas([clipobject])
    
    for indx in range(len(guide_xfocal)):
        interior.stroke(path.rect((guide_yfocal[indx]/10.)-guide_size*0.5, 
                                  (guide_xfocal[indx]/10.)-guide_size*0.5, 
                                  guide_size, guide_size),
                        [style.linewidth.THick, color.cmyk.Black])
        interior.text((guide_yfocal[indx]/10.)+guide_size*0.66,
                      (guide_xfocal[indx]/10.), 
                      r"\font\myfont=cmr10 at 35pt {\myfont "+ 
                      str(guidenum[indx])+"}",
                      [text.halign.boxleft, text.valign.middle, 
                       text.size.Huge])
        
    return interior

def whiteout_layer(holes):
    whiteout= canvas.canvas()
    for indx in range(len(holes['xfocal'])):
        radius=0.25
        if(holes['holetype'][indx] == 'GUIDE'):
            radius=0.54
        if(holes['holetype'][indx] == 'ALIGNMENT'):
            radius=0.1
        if(holes['holetype'][indx] == 'MANGA'):
            radius=0.4
        if(holes['holetype'][indx] == 'MANGA_SINGLE'):
            radius=0.4
        if(holes['holetype'][indx] == 'MANGA_ALIGNMENT'):
            radius=0.2
        if(holes['holetype'][indx] == 'CENTER'):
            radius=0.36
        if(holes['holetype'][indx] == 'TRAP'):
            radius=0.45
        whiteout.fill(path.circle(holes['yfocal'][indx]/10., 
                                  holes['xfocal'][indx]/10., radius), 
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
    outline.stroke(path.line(-full_radius, tab_ysize*0.5, 
                              -full_radius-tab_xsize, tab_ysize*0.5),
                   [style.linewidth.thick])
    outline.stroke(path.line(-full_radius-tab_xsize, -tab_ysize*0.5, 
                              -full_radius-tab_xsize, tab_ysize*0.5),
                   [style.linewidth.thick])
    outline.stroke(path.line(-full_radius-tab_xsize,  0., 
                             -limit_radius,  0.),
                   [style.linewidth.thick])
    return outline

def overlay_print(plateid):
    '''
    This function returns a plate overlay as a pyx.document object.
    The calling script can determine what to do with it. To print this
    object as a PDF:
    
    overlay = overlay_print(plateid=12345)
    overlay.writePDFfile(destination_path)
    
    '''
    outpdf= sdssPath.full('plateLines-print', plateid=plateid)

	# Get the needed files
    plateHolesSorted_file = sdssPath.full('plateHolesSorted', plateid=plateid)
    if not os.path.isfile(plateHolesSorted_file):
        raise IOError("File not found: {0}".format(plateHolesSorted_file))

    platePlans_file = sdssPath.full('platePlans')
    if not os.path.isfile(platePlans_file):
	    raise IOError("File not found: {0}".format(platePlans_file))
    
    # Read in holes data, extract meta data
    holes_yanny= yanny.yanny(plateHolesSorted_file)
    racen= holes_yanny['raCen']
    deccen= holes_yanny['decCen']
    designid= holes_yanny['designid']
    ha= holes_yanny['ha']
    platerun=holes_yanny['platerun']
    holes= holes_yanny['STRUCT1']

    # Read in plans
    plans= yanny.yanny(platePlans_file)
    iplan= np.nonzero(np.array(plans['PLATEPLANS']['plateid']) == plateid)[0]
    survey= plans['PLATEPLANS']['survey'][iplan]
    programname= plans['PLATEPLANS']['programname'][iplan]

    # Texify the string
    programname_str = programname
    programname_str = re.sub("_", "\_", programname_str)

    # Create information string
    information= r"\font\myfont=cmr10 at 40pt {\myfont"
    information+=" Plate="+str(plateid)+"; "
    information+="Design="+str(designid)+"; "
    information+="Survey="+str(survey)+"; "
    information+="Program="+str(programname_str)+"; "
    information+="RA="+str(racen)+"; "
    information+="Dec="+str(deccen)+"; "
    information+="HA="+str(np.float32((ha.split())[0]))+"."
    information+="}"
   
    # Create message
    message= "Una placa para probar el proceso de impresion"
    message_tex= r"\font\myfont=cmr10 at 40pt {\myfont "+message+"}"

    apogee= apogee_layer(holes)
    guide= guide_layer(holes)
    whiteout= whiteout_layer(holes)
    plate_circle= plate_circle_layer(plateid, information, message_tex)
    outline= outline_layer() # pyx.canvas object

    outline.insert(apogee)
    outline.insert(guide)
    outline.insert(plate_circle)
    outline.insert(whiteout)
    
    pformat=document.paperformat(limit_radius*2., limit_radius*2.)
    final=document.page(outline, paperformat=pformat)
    
    return document.document(pages=[final])
    
    #doc= document.document(pages=[final])
    #doc.writePDFfile(outpdf)

Attribute VB_Name = "NewMacros"
Sub tiles()
Attribute tiles.VB_ProcData.VB_Invoke_Func = "Normal.NewMacros.tiles"
'
' tiles Macro
'
'

Dim tile_v As Integer
tile_v = 1

Dim lat As Double
lat = 18.03855775

Dim longitude As Double
longitude = 121.9866903

Dim tile_h As Integer
tile_h = 1


Do While tile_h <= 8
 lat = 18.03855775
 Do While tile_v <= 8
    Selection.TypeText Text:="<Placemark>"
    Selection.TypeParagraph
    Selection.TypeText Text:="<name>Bluewater Surface #"
    Selection.TypeText Text:=Chr(64 + tile_h)
    Selection.TypeText Text:=tile_v
    Selection.TypeText Text:="</name>"
    Selection.TypeParagraph
    Selection.TypeText Text:="<description>used for Therion surface drawing</description>"
    Selection.TypeParagraph
    Selection.TypeText Text:="        <LookAt>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <gx:TimeStamp><when>2020-09-09</when></gx:TimeStamp>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <longitude>"
    Selection.TypeText Text:=longitude
    Selection.TypeText Text:="</longitude>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <latitude>"
    Selection.TypeText Text:=lat
    Selection.TypeText Text:="            </latitude>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <altitude>0</altitude>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <heading>0.00</heading>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <tilt>0</tilt>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <range>1000</range>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>"
    Selection.TypeParagraph
    Selection.TypeText Text:="        </LookAt>"
    Selection.TypeParagraph
    Selection.TypeText Text:="        <styleUrl>#msn_wht-pushpin</styleUrl>"
    Selection.TypeParagraph
    Selection.TypeText Text:="        <Point>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <altitudeMode>relativeToGround</altitudeMode>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <gx:drawOrder>1</gx:drawOrder>"
    Selection.TypeParagraph
    Selection.TypeText Text:="            <coordinates>"
    Selection.TypeText Text:=longitude
    Selection.TypeText Text:=","
    Selection.TypeText Text:=lat
    Selection.TypeText Text:=",1000</coordinates>"
    Selection.TypeParagraph
    Selection.TypeText Text:="        </Point>"
    Selection.TypeParagraph
    Selection.TypeText Text:="</Placemark>"
    Selection.TypeParagraph
    
    tile_v = tile_v + 1
    lat = lat - 0.00570282
  Loop
  tile_h = tile_h + 1
  tile_v = 1
  longitude = longitude + 0.009723578
 Loop
 End Sub

#!/usr/bin/env python3.1

# convert_ui.py version 1.1, 25th August 2010
# written by alpaca (Stefan Reutter)
# This file converts ui layout files to XML and vice-versa


import io, struct, sys, os

from xml.dom.minidom import parse

# some useful definitions
class TypeCastReader(io.BufferedReader):
    def readByte(self):
        return(struct.unpack("B",self.read(1))[0])
    def readInt(self):
        return(struct.unpack("i",self.read(4))[0])
    def readUInt(self):
        return(struct.unpack("I",self.read(4))[0])
    def readShort(self):
        return(struct.unpack("h",self.read(2))[0])
    def readUShort(self):
        return(struct.unpack("H",self.read(2))[0])
    def readFloat(self):
        return(struct.unpack("f",self.read(4))[0])
    def readDouble(self):
        return(struct.unpack("d",self.read(8))[0])
    def readBool(self):
        return(self.read(1) != b'\x00')
    # Returns xml-escaped strings because the rest of the program doesn't
    # handle escaping anywhere
    def readUTF16(self):
        length = self.readUShort()
        encodedString = self.read(length*2)
        string = encodedString.decode("UTF-16")
        return(string.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\r", "&#x0D;"))
    def readASCII(self):
        length = self.readUShort()
        encodedString = self.read(length)
        string = encodedString.decode("ascii")
        return(string.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\r", "&#x0D;"))
        
class TypeCastWriter(io.BufferedWriter):
    def writeByte(self,arg):
        self.write(struct.pack("B",arg))
    def writeInt(self,arg):
        self.write(struct.pack("i",arg))
    def writeUInt(self,arg):
        self.write(struct.pack("I",arg))
    def writeShort(self,arg):
        self.write(struct.pack("h",arg))
    def writeUShort(self,arg):
        self.write(struct.pack("H",arg))
    def writeFloat(self,arg):
        self.write(struct.pack("f",arg))
    def writeDouble(self,arg):
        self.write(struct.pack("d",arg))
    def writeBool(self,arg):
        if arg:
            self.write(b'\x01')
        else:
            self.write(b'\x00')
    def writeUTF16(self,arg):
        self.writeUShort(len(arg))
        self.write(arg.encode("UTF-16")[2:])
    def writeASCII(self,arg):
        self.writeUShort(len(arg))
        self.write(arg.encode("ascii"))

class debuggable_converter:
  def indented_print(self, str, handle):
    print("%s%s (%x)" % (" "*self.indent, str, handle.tell()))
  def debug(self, name, handle):
    print("%s%s.%s=%s (%x)" % (" "*self.indent, type(self).__name__, name, self.__dict__[name], handle.tell()))

class uiEntry(debuggable_converter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.id = 0
        self.title = "" #ascii
        self.title2 = "" #ascii
        self.string10 = "" #ascii
        self.xOff = 0
        self.yOff = 0
        self.flag1 = 0
        self.flag2 = 0
        self.flag3 = 0
        
        self.flag11 = 0
        self.flag12 = 0
        self.flag13 = 0
        self.flag14 = 0
        self.flag6 = 0
        self.flag7 = 0
        self.flag8 = 0
        self.flag9 = 0
        
        self.parentName = "" #ascii
        
        self.int1 = 0
        
        self.tooltip = ""
        self.tooltipText = ""
        
        self.int3 = 0
        self.int4 = 0
        self.flag4 = 0
        self.script = ""
        

        self.numTGAs = 0
        self.TGAs = []
    
        self.int5 = 0
        self.int6 = 0
        self.numStates = 0
        
        self.states = []
        
        self.int26 = 0
        
        self.events = []
        
        self.eventsEnd = "" #ascii
        
        self.int27 = 0
        self.int28 = 0 # number of mysterious entries
        self.numChildren = 0
        self.children = []
        
        # after the last child follows a template string
        self.template = "" #ascii
        self.flag5 = 0
        
    def readFrom(self, handle):
        """
        Reads from a TypeCastReader handle
        """
        self.id = handle.readInt()
        self.title = handle.readASCII()
        if self.version >= 43:
          self.title2 = handle.readASCII()
        self.xOff = handle.readInt()
        self.yOff = handle.readInt()
        self.flag1 = handle.readByte()
        self.flag2 = handle.readByte()
        self.flag3 = handle.readByte()
        # revision: int0 are flags
        self.flag11 = handle.readByte()
        self.flag12 = handle.readByte()
        self.flag13 = handle.readByte()
        self.flag14 = handle.readByte()
        if self.version >= 47:
          self.flag6 = handle.readByte()
        if self.version >= 50:
          self.flag7 = handle.readByte()
          self.flag8 = handle.readByte()
          self.flag9 = handle.readByte()

        self.parentName = handle.readASCII()
        
        self.int1 = handle.readInt()
        
        self.tooltip = handle.readUTF16()
        self.tooltipText = handle.readUTF16()
        
        self.int3 = handle.readInt()

        if self.version >= 33:
          self.flag4 = handle.readByte()
        if self.version >= 39:
          self.int4 = handle.readInt()
        
        self.script = handle.readASCII()

        self.numTGAs = handle.readInt()
        for i in range(self.numTGAs):
            tga = tgaEntry(self.version, self.indent + 2)
            tga.readFrom(handle)
            self.TGAs.append(tga)

        self.int5 = handle.readInt()
        self.int6 = handle.readInt()

        self.numStates = handle.readInt()

        for i in range(self.numStates):
            newstate = state(self.version, self.indent + 2)
            newstate.readFrom(handle)
            self.states.append(newstate)

        self.int26 = handle.readInt()

        # In version 51 there's sometimes a mystery byte 00 here,
        # and sometimes there isn't.
        # (as far as I can tell)

        ev = handle.readASCII()
        while ev != "events_end":
            self.events.append(ev)
            ev = handle.readASCII()
        
        self.eventsEnd = ev

        self.int27 = handle.readInt()
        if self.version >= 39:
          self.int28 = handle.readInt()

          # Just throw out decoding and hope for the best
          for i in range(self.int28):
            handle.readASCII() # name
            handle.readASCII() # or 00 00
            for j in range(16):
              handle.readInt() # some of them are floats (second one especially)

        self.numChildren = handle.readInt()
        
        for i in range(self.numChildren):
            child = uiEntry(self.version, self.indent + 2)
            child.readFrom(handle)
            self.children.append(child)
        
        self.template = handle.readASCII()
    
        if self.version >= 44:
          self.flag5 = handle.readByte()
        if self.version >= 49:
          self.string10 = handle.readASCII()
    
    def writeTo(self, handle):
        """
        Writes to a TypeCastWriter handle
        """
        handle.writeInt(self.id)
        handle.writeASCII(self.title)
        if self.version >= 43:
          handle.writeASCII(self.title2)
        
        handle.writeInt(self.xOff)
        handle.writeInt(self.yOff)
        handle.writeByte(self.flag1)
        handle.writeByte(self.flag2)
        handle.writeByte(self.flag3)
        
        handle.writeByte(self.flag11)
        handle.writeByte(self.flag12)
        handle.writeByte(self.flag13)
        handle.writeByte(self.flag14)
        if self.version >= 47:
          handle.writeByte(self.flag6)
        if self.version >= 50:
          handle.writeByte(self.flag7)
          handle.writeByte(self.flag8)
          handle.writeByte(self.flag9)
        
        handle.writeASCII(self.parentName)
        
        handle.writeInt(self.int1)
        
        handle.writeUTF16(self.tooltip)
        handle.writeUTF16(self.tooltipText)
        
        handle.writeInt(self.int3)
        if self.version >= 33:
          handle.writeByte(self.flag4)
        if self.version >= 39:
          handle.writeInt(self.int4)
        
        handle.writeASCII(self.script)
        
        handle.writeInt(self.numTGAs)
        
        for tga in self.TGAs:
            tga.writeTo(handle)
        
        handle.writeInt(self.int5)
        handle.writeInt(self.int6)
        
        handle.writeInt(self.numStates)
        
        for state in self.states:
            state.writeTo(handle)
        
        handle.writeInt(self.int26)
        
        for ev in self.events:
            handle.writeASCII(ev)
        
        handle.writeASCII(self.eventsEnd)
        
        handle.writeInt(self.int27)
        if self.version >= 39:
          handle.writeInt(self.int28)
        
        handle.writeInt(self.numChildren)
        
        for child in self.children:
            child.writeTo(handle)
            
        handle.writeASCII(self.template)
        
        if self.version >= 44:
          handle.writeByte(self.flag5)

        if self.version >= 49:
          handle.writeASCII(self.string10)

    def writeToXML(self, handle):
        """
        Writes to a text file handle
        """
        handle.write("""%(indent)s<uiEntry>
%(indent+1)s<id>%(id)i</id>
%(indent+1)s<title>%(title)s</title>
%(indent+1)s<title2>%(title2)s</title2>
%(indent+1)s<string10>%(string10)s</string10>
%(indent+1)s<xOff>%(xOff)i</xOff>
%(indent+1)s<yOff>%(yOff)i</yOff>
%(indent+1)s<flag1>%(flag1)i</flag1>
%(indent+1)s<flag2>%(flag2)i</flag2>
%(indent+1)s<flag3>%(flag3)i</flag3>
%(indent+1)s<flag11>%(flag11)i</flag11>
%(indent+1)s<flag12>%(flag12)i</flag12>
%(indent+1)s<flag13>%(flag13)i</flag13>
%(indent+1)s<flag14>%(flag14)i</flag14>
%(indent+1)s<flag6>%(flag6)i</flag6>
%(indent+1)s<flag7>%(flag7)i</flag7>
%(indent+1)s<flag8>%(flag8)i</flag8>
%(indent+1)s<flag9>%(flag9)i</flag9>
%(indent+1)s<parentName>%(parentName)s</parentName>
%(indent+1)s<int1>%(int1)i</int1>
%(indent+1)s<tooltip>%(tooltip)s</tooltip>
%(indent+1)s<tooltipText>%(tooltipText)s</tooltipText>
%(indent+1)s<int3>%(int3)i</int3>
%(indent+1)s<int4>%(int4)i</int4>
%(indent+1)s<flag4>%(flag4)i</flag4>
%(indent+1)s<script>%(script)s</script>
%(indent+1)s<tgas num="%(numTGAs)i">
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "id": self.id, "title": self.title, "title2": self.title2, "string10" : self.string10, "xOff": self.xOff, "yOff": self.yOff, "flag1": self.flag1, "flag2": self.flag2, "flag3": self.flag3, "flag11": self.flag11, "flag12": self.flag12, "flag13": self.flag13, "flag14": self.flag14, "flag6": self.flag6, "flag7": self.flag7, "flag8": self.flag8, "flag9": self.flag9, "parentName": self.parentName, "int1": self.int1, "tooltip": self.tooltip, "tooltipText": self.tooltipText, "int3": self.int3, "int4": self.int4, "flag4": self.flag4, "script": self.script, "numTGAs": self.numTGAs})
        for tga in self.TGAs:
            tga.writeToXML(handle)
        
        handle.write("""%(indent+1)s</tgas>
%(indent+1)s<int5>%(int5)i</int5>
%(indent+1)s<int6>%(int6)i</int6>
%(indent+1)s<states num="%(numStates)i">
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "int5": self.int5, "int6": self.int6, "numStates": self.numStates})

        for state in self.states:
            state.writeToXML(handle)
        
        handle.write("""%(indent+1)s</states>
%(indent+1)s<int26>%(int26)i</int26>
%(indent+1)s<events>
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "int26": self.int26})
        
        for ev in self.events:
            handle.write("%(indent+2)s<event>%(ev)s</event>\n"%{"indent+2": "  "*(self.indent + 2), "ev": ev})
        
        handle.write("""%(indent+1)s</events>
%(indent+1)s<eventsEnd>%(eventsEnd)s</eventsEnd>
%(indent+1)s<int27>%(int27)i</int27>
%(indent+1)s<int28>%(int28)i</int28>
%(indent+1)s<children num="%(numChildren)i">
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "eventsEnd": self.eventsEnd, "int27": self.int27, "int28": self.int28, "numChildren": self.numChildren})
        
        for child in self.children:
            child.writeToXML(handle)
        
        handle.write("""%(indent+1)s</children>
%(indent+1)s<template>%(template)s</template>
%(indent+1)s<flag5>%(flag5)i</flag5>
%(indent)s</uiEntry>\n"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "flag5": self.flag5, "template": self.template})
        
    def constructFromNode(self, node):
        """
        Constructs a UI entry from a uiEntry XML node
        """
        if node.nodeName != "uiEntry":
            raise(Exception("Not a ui node"))
            return 
        
        
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = int(child.firstChild.data)
            elif child.nodeName == "title":
                self.title = child.firstChild.data
            elif child.nodeName == "title2":
                if len(child.childNodes) > 0:
                    self.title2 = child.firstChild.data
            elif child.nodeName == "string10":
                if len(child.childNodes) > 0:
                    self.string10 = child.firstChild.data
            elif child.nodeName == "xOff":
                self.xOff = int(child.firstChild.data)
            elif child.nodeName == "yOff":
                self.yOff = int(child.firstChild.data)
            elif child.nodeName == "flag1":
                self.flag1 = int(child.firstChild.data)
            elif child.nodeName == "flag2":
                self.flag2 = int(child.firstChild.data)
            elif child.nodeName == "flag3":
                self.flag3 = int(child.firstChild.data)
            elif child.nodeName == "flag5":
                self.flag5 = int(child.firstChild.data)
            elif child.nodeName == "flag11":
                self.flag11 = int(child.firstChild.data)
            elif child.nodeName == "flag12":
                self.flag12 = int(child.firstChild.data)
            elif child.nodeName == "flag13":
                self.flag13 = int(child.firstChild.data)
            elif child.nodeName == "flag14":
                self.flag14 = int(child.firstChild.data)
            elif child.nodeName == "flag6":
                self.flag6 = int(child.firstChild.data)
            elif child.nodeName == "flag7":
                self.flag7 = int(child.firstChild.data)
            elif child.nodeName == "flag8":
                self.flag8 = int(child.firstChild.data)
            elif child.nodeName == "flag9":
                self.flag9 = int(child.firstChild.data)
            elif child.nodeName == "parentName":
                if len(child.childNodes) > 0:
                    self.parentName = child.firstChild.data
            elif child.nodeName == "int1":
                self.int1 = int(child.firstChild.data)
            elif child.nodeName == "tooltip":
                if len(child.childNodes) > 0:
                    self.tooltip = child.firstChild.data
            elif child.nodeName == "tooltipText":
                if len(child.childNodes) > 0:
                    self.tooltipText = child.firstChild.data
            elif child.nodeName == "int3":
                self.int3 = int(child.firstChild.data)
            elif child.nodeName == "flag4":
                self.flag4 = int(child.firstChild.data)
            elif child.nodeName == "int4":
                self.int4 = int(child.firstChild.data)
            elif child.nodeName == "script":
                if len(child.childNodes) > 0:
                    self.script = child.firstChild.data
            elif child.nodeName == "tgas":
                self.numTGAs = int(child.attributes.getNamedItem("num").firstChild.data)
                for tgaNode in child.childNodes:
                    if tgaNode.nodeName == "tga":
                        tga = tgaEntry(self.version, self.indent)
                        tga.constructFromNode(tgaNode)
                        self.TGAs.append(tga)
            elif child.nodeName == "int5":
                self.int5 = int(child.firstChild.data)
            elif child.nodeName == "int6":
                self.int6 = int(child.firstChild.data)
            elif child.nodeName == "states":
                self.numStates = int(child.attributes.getNamedItem("num").firstChild.data)
                for stateNode in child.childNodes:
                    if stateNode.nodeName == "state":
                        astate = state(self.version, self.indent)
                        astate.constructFromNode(stateNode)
                        self.states.append(astate)
            elif child.nodeName == "int26":
                self.int26 = int(child.firstChild.data)
            elif child.nodeName == "events":
                for eventNode in child.childNodes:
                    if eventNode.nodeName == "event":
                        if eventNode.hasChildNodes():
                            self.events.append(eventNode.firstChild.data)
                        else:
                            self.events.append("")
            elif child.nodeName == "eventsEnd":
                self.eventsEnd = child.firstChild.data      
            elif child.nodeName == "int27":
                self.int27 = int(child.firstChild.data)
            elif child.nodeName == "int28":
                self.int28 = int(child.firstChild.data)   
            elif child.nodeName == "children":   
                self.numChildren = int(child.attributes.getNamedItem("num").firstChild.data)
                for childNode in child.childNodes:
                    if childNode.nodeName == "uiEntry":
                        ui = uiEntry(self.version, self.indent)
                        ui.constructFromNode(childNode)
                        self.children.append(ui)
            elif child.nodeName == "template":
                if len(child.childNodes) > 0:
                    self.template = child.firstChild.data
                        
class tgaEntry(debuggable_converter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.id = 0 #int
        self.path = "" #ascii
        self.width = 0 #int
        self.height = 0 #int
        self.int1 = 0 #int (i guess this could be a color overlay)
        
    def readFrom(self, handle):
        """
        Reads from a TypeCastReader handle
        """
        self.id = handle.readInt()
        self.path = handle.readASCII()
        self.width = handle.readInt()
        self.height = handle.readInt()
        self.int1 = handle.readInt()
    
    def writeTo(self, handle):
        """
        Writes to a TypeCastWriter handle
        """
        handle.writeInt(self.id)
        handle.writeASCII(self.path)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
        handle.writeInt(self.int1)
        
    def writeToXML(self, handle):
        """
        Writes to a text file handle
        """
        handle.write("%(indent)s<tga>\n%(indent+1)s<id>%(id)i</id>\n%(indent+1)s<path>%(path)s</path>\n%(indent+1)s<width>%(width)i</width>\n%(indent+1)s<height>%(height)i</height>\n%(indent+1)s<int1>%(int1)i</int1>\n%(indent)s</tga>\n"%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent+1), "id": self.id, "path": self.path, "width": self.width, "height": self.height, "int1": self.int1})
        
    def constructFromNode(self, node):
        """
        Constructs a tga entry from a tga XML node
        """
        if node.nodeName != "tga":
            raise(Exception("Not a tga node"))
            return 
        
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = int(child.firstChild.data)
            elif child.nodeName == "path":
                if len(child.childNodes) > 0:
                    self.path = child.firstChild.data
            elif child.nodeName == "width":
                self.width = int(child.firstChild.data)
            elif child.nodeName == "height":
                self.height = int(child.firstChild.data)
            elif child.nodeName == "int1":
                self.int1 = int(child.firstChild.data)

class tgaUse(debuggable_converter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.id = 0 #int
        self.xOff = 0
        self.yOff = 0
        self.width = 0
        self.height = 0
        #self.linkID = 0 this is actually a color multiplier; each color channel is multiplied with the color channel here
        self.redMultiply = 0
        self.greenMultiply = 0
        self.blueMultiply = 0
        self.alphaMultiply = 0
        self.flag1 = 0
        self.flag2 = 0 # flip horizontal
        self.flag3 = 0 # flip vertical
        self.position = 0 # int, this seems to indicate position as 0 = ? (span?), 1 = top left, 2 = top, 3 = top right, 4 = center left, 5 = center, 6 = center right, 7 = bottom left, 8 = bottom, 9 = bottom right
        # |1|2|3|
        # |4|5|6|
        # |7|8|9|
        self.flag4 = 0 # stretch horizontal
        self.flag5 = 0 # stretch vertical
        self.int1 = 0
        self.int2 = 0
        self.int3 = 0
    
    def readFrom(self, handle):
        """
        Reads from a TypeCastReader handle
        """
        self.id = handle.readInt()
        self.xOff = handle.readInt()
        self.yOff = handle.readInt()
        self.width = handle.readInt()
        self.height = handle.readInt()
        self.blueMultiply = handle.readByte()
        self.greenMultiply = handle.readByte()
        self.redMultiply = handle.readByte()
        self.alphaMultiply = handle.readByte()
        self.flag1 = handle.readByte()
        self.flag2 = handle.readByte()
        self.flag3 = handle.readByte()
        self.position = handle.readInt()
        self.flag4 = handle.readByte()
        self.flag5 = handle.readByte()
        self.int1 = handle.readInt()
        self.int2 = handle.readInt()
        self.int3 = handle.readInt()
    
    def writeTo(self, handle):
        """
        Writes to a TypeCastWriter handle
        """
        handle.writeInt(self.id)
        handle.writeInt(self.xOff)
        handle.writeInt(self.yOff)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
        handle.writeByte(self.blueMultiply)
        handle.writeByte(self.greenMultiply)
        handle.writeByte(self.redMultiply)
        handle.writeByte(self.alphaMultiply)
        handle.writeByte(self.flag1)
        handle.writeByte(self.flag2)
        handle.writeByte(self.flag3)
        handle.writeInt(self.position)
        handle.writeByte(self.flag4)
        handle.writeByte(self.flag5)
        handle.writeInt(self.int1)
        handle.writeInt(self.int2)
        handle.writeInt(self.int3)

    
    def writeToXML(self, handle):
        """
        Writes to a text file handle
        """
        handle.write("%(indent)s<tgaUse>\n%(indent+1)s<id>%(id)i</id>\n%(indent+1)s<xOff>%(xOff)i</xOff>\n%(indent+1)s<yOff>%(yOff)i</yOff>\n%(indent+1)s<width>%(width)i</width>\n%(indent+1)s<height>%(height)i</height>\n%(indent+1)s<blueMultiply>%(blueMultiply)i</blueMultiply>\n%(indent+1)s<greenMultiply>%(greenMultiply)i</greenMultiply>\n%(indent+1)s<redMultiply>%(redMultiply)i</redMultiply>\n%(indent+1)s<alphaMultiply>%(alphaMultiply)i</alphaMultiply>\n%(indent+1)s<flag1>%(flag1)i</flag1>\n%(indent+1)s<mirror_horizontally>%(flag2)i</mirror_horizontally>\n%(indent+1)s<mirror_vertically>%(flag3)i</mirror_vertically>\n%(indent+1)s<position>%(position)i</position>\n%(indent+1)s<stretches_horizontally>%(flag4)i</stretches_horizontally>\n%(indent+1)s<stretches_vertically>%(flag5)i</stretches_vertically>\n%(indent+1)s<int1>%(int1)i</int1>\n%(indent+1)s<int2>%(int2)i</int2>\n%(indent+1)s<int3>%(int3)i</int3>\n%(indent)s</tgaUse>\n"%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent+1), "id": self.id, "xOff": self.xOff, "yOff": self.yOff, "width": self.width, "height": self.height, "blueMultiply": self.blueMultiply, "greenMultiply": self.greenMultiply, "redMultiply": self.redMultiply, "alphaMultiply": self.alphaMultiply, "flag1": self.flag1, "flag2": self.flag2, "flag3": self.flag3, "position": self.position, "flag4": self.flag4, "flag5": self.flag5, "int1": self.int1, "int2": self.int2, "int3": self.int3})

    def constructFromNode(self, node):
        """
        Constructs a tgaUse entry from a tgaUse XML node
        """
        if node.nodeName != "tgaUse":
            raise(Exception("Not a tgaUse node"))
            return 
        
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = int(child.firstChild.data)
            elif child.nodeName == "xOff":
                self.xOff = int(child.firstChild.data)
            elif child.nodeName == "yOff":
                self.yOff = int(child.firstChild.data)
            elif child.nodeName == "width":
                self.width = int(child.firstChild.data)
            elif child.nodeName == "height":
                self.height = int(child.firstChild.data)
            elif child.nodeName == "int1":
                self.int1 = int(child.firstChild.data)
            elif child.nodeName == "blueMultiply":
                self.blueMultiply = int(child.firstChild.data)
            elif child.nodeName == "greenMultiply":
                self.greenMultiply = int(child.firstChild.data)
            elif child.nodeName == "redMultiply":
                self.redMultiply = int(child.firstChild.data)
            elif child.nodeName == "alphaMultiply":
                self.alphaMultiply = int(child.firstChild.data)
            elif child.nodeName == "flag1":
                self.flag1 = int(child.firstChild.data)
            elif child.nodeName == "mirror_horizontally":
                self.flag2 = int(child.firstChild.data)
            elif child.nodeName == "mirror_vertically":
                self.flag3 = int(child.firstChild.data)
            elif child.nodeName == "position":
                self.position = int(child.firstChild.data)
            elif child.nodeName == "stretches_horizontally":
                self.flag4 = int(child.firstChild.data)
            elif child.nodeName == "stretches_vertically":
                self.flag5 = int(child.firstChild.data)
            elif child.nodeName == "int1":
                self.int1 = int(child.firstChild.data)
            elif child.nodeName == "int2":
                self.int2 = int(child.firstChild.data)
            elif child.nodeName == "int3":
                self.int3 = int(child.firstChild.data)

class state(debuggable_converter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.title = ""
        self.twui = ""
        self.TGAUses = []
        self.transitions = []
        
        self.stateText = ""
        self.tooltip = ""
        self.localisationID = ""
        self.tooltipID = ""
        
        self.stateDescription = ""
        self.eventText = ""
        
    def readFrom(self, handle):
        """
        Reads from a TypeCastReader handle
        """
        self.id = handle.readInt()
        self.title = handle.readASCII()
        self.width = handle.readInt()
        self.height = handle.readInt()
                                     
        self.stateText = handle.readUTF16()
        self.tooltip = handle.readUTF16()
        self.int7 = handle.readInt()
        self.int8 = handle.readInt()
        self.int9 = handle.readInt()
        self.int10 = handle.readInt()
        self.int11 = handle.readInt()
        
        self.flag7 = handle.readByte()
        self.localisationID = handle.readUTF16()
        self.tooltipID = handle.readUTF16()
        
        self.font = handle.readASCII()
        self.int12 = handle.readInt()
        self.int13 = handle.readInt()
        self.int14 = handle.readInt() # determines what the color of each pixel in the texture is multiplied with (alpha overlay if you like)
        if self.version >= 43:
          self.twui = handle.readASCII()
        self.int15 = handle.readInt()
        self.int16 = handle.readInt()
        self.int17 = handle.readInt()
        self.flag8 = handle.readByte()
        self.flag9 = handle.readByte()
        self.flag10 = handle.readByte()
        
        self.normalt0 = handle.readASCII()
        
        self.int18 = handle.readInt()
        self.int19 = handle.readInt()
        self.int20 = handle.readInt()
        self.int21 = handle.readInt()
        self.stateDescription = handle.readASCII()
        self.eventText = handle.readASCII()
        
        self.numTGAUses = handle.readInt()
        for i in range(self.numTGAUses):
            tga = tgaUse(self.version, self.indent + 2)
            tga.readFrom(handle)
            self.TGAUses.append(tga)
        
        self.int23 = handle.readInt()
        self.int24 = handle.readInt()
        
        self.numTransitions = handle.readInt()
        for i in range(self.numTransitions):
            trans = transition(self.version, self.indent + 2)
            trans.readFrom(handle)
            self.transitions.append(trans)


    
    def writeTo(self, handle):
        """
        Writes to a TypeCastWriter handle
        """
        
        handle.writeInt(self.id)
        handle.writeASCII(self.title)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
                                     
        handle.writeUTF16(self.stateText)
        handle.writeUTF16(self.tooltip)
        handle.writeInt(self.int7)
        handle.writeInt(self.int8)
        handle.writeInt(self.int9)
        handle.writeInt(self.int10)
        handle.writeInt(self.int11)
        
        handle.writeByte(self.flag7)
        handle.writeUTF16(self.localisationID)
        handle.writeUTF16(self.tooltipID)
        
        handle.writeASCII(self.font)
        handle.writeInt(self.int12)
        handle.writeInt(self.int13)
        handle.writeInt(self.int14)
        if self.version >= 43:
          handle.writeASCII(self.twui)
        handle.writeInt(self.int15)
        handle.writeInt(self.int16)
        handle.writeInt(self.int17)
        handle.writeByte(self.flag8)
        handle.writeByte(self.flag9)
        handle.writeByte(self.flag10)
        
        handle.writeASCII(self.normalt0)
        
        handle.writeInt(self.int18)
        handle.writeInt(self.int19)
        handle.writeInt(self.int20)
        handle.writeInt(self.int21)
        
        handle.writeASCII(self.stateDescription)
        handle.writeASCII(self.eventText)
        
        handle.writeInt(self.numTGAUses)
        
        for tgaU in self.TGAUses:
            tgaU.writeTo(handle)
        
        handle.writeInt(self.int23)
        handle.writeInt(self.int24)
        
        handle.writeInt(self.numTransitions)
        for trans in self.transitions:
            trans.writeTo(handle)
            
    
    def writeToXML(self, handle):
        """
        Writes to a text file handle
        """
        handle.write("""%(indent)s<state>
%(indent+1)s<id>%(id)i</id>
%(indent+1)s<title>%(title)s</title>
%(indent+1)s<width>%(width)i</width>
%(indent+1)s<height>%(height)i</height>
%(indent+1)s<stateText>%(stateText)s</stateText>
%(indent+1)s<tooltip>%(tooltip)s</tooltip>
%(indent+1)s<int7>%(int7)i</int7>
%(indent+1)s<int8>%(int8)i</int8>
%(indent+1)s<int9>%(int9)i</int9>
%(indent+1)s<int10>%(int10)i</int10>
%(indent+1)s<int11>%(int11)i</int11>
%(indent+1)s<flag7>%(flag7)i</flag7>
%(indent+1)s<localisationID>%(localisationID)s</localisationID>
%(indent+1)s<tooltipID>%(tooltipID)s</tooltipID>
%(indent+1)s<font>%(font)s</font>
%(indent+1)s<int12>%(int12)i</int12>
%(indent+1)s<int13>%(int13)i</int13>
%(indent+1)s<textAlphaMultiply>%(int14)i</textAlphaMultiply>
%(indent+1)s<twui>%(twui)s</twui>
%(indent+1)s<int15>%(int15)i</int15>
%(indent+1)s<int16>%(int16)i</int16>
%(indent+1)s<int17>%(int17)i</int17>
%(indent+1)s<flag8>%(flag8)i</flag8>
%(indent+1)s<flag9>%(flag9)i</flag9>
%(indent+1)s<flag10>%(flag10)i</flag10>
%(indent+1)s<normalt0>%(normalt0)s</normalt0>
%(indent+1)s<int18>%(int18)i</int18>
%(indent+1)s<int19>%(int19)i</int19>
%(indent+1)s<int20>%(int20)i</int20>
%(indent+1)s<int21>%(int21)i</int21>
%(indent+1)s<stateDescription>%(stateDescription)s</stateDescription>
%(indent+1)s<eventText>%(eventText)s</eventText>
%(indent+1)s<tgaUses num="%(numTGAUses)i">
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "id": self.id, "title": self.title, "width": self.width, "height": self.height, "stateText": self.stateText, "tooltip": self.tooltip, "int7": self.int7, "int8": self.int8, "int9": self.int9, "int10": self.int10, "int11": self.int11, "flag7": self.flag7, "localisationID": self.localisationID, "tooltipID": self.tooltipID, "font": self.font, "int12": self.int12, "int13": self.int13, "int14": self.int14, "twui": self.twui, "int15": self.int15, "int16": self.int16, "int17": self.int17, "flag8": self.flag8, "flag9": self.flag9, "flag10": self.flag10, "normalt0": self.normalt0, "int18": self.int18, "int19": self.int19, "int20": self.int20, "int21": self.int21, "stateDescription": self.stateDescription, "eventText": self.eventText, "numTGAUses": self.numTGAUses})
        
        for i in range(self.numTGAUses):
            self.TGAUses[i].writeToXML(handle)
        
        handle.write("""%(indent+1)s</tgaUses>
%(indent+1)s<int23>%(int23)i</int23>
%(indent+1)s<int24>%(int24)i</int24>
%(indent+1)s<transitions num="%(numTransitions)s">
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1), "int23": self.int23, "int24": self.int24, "numTransitions": self.numTransitions})
        
        for i in range(self.numTransitions):
            self.transitions[i].writeToXML(handle)
        
        handle.write("%(indent+1)s</transitions>\n%(indent)s</state>\n"%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent + 1)})
        
    def constructFromNode(self, node):
        """
        Constructs a state entry from a state XML node
        """
        if node.nodeName != "state":
            raise(Exception("Not a state node"))
            return 
        
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = int(child.firstChild.data)
            elif child.nodeName == "title":
                if len(child.childNodes) > 0:
                    self.title = child.firstChild.data
            elif child.nodeName == "width":
                self.width = int(child.firstChild.data)
            elif child.nodeName == "height":
                self.height = int(child.firstChild.data)
            elif child.nodeName == "stateText":
                if len(child.childNodes) > 0:
                    self.stateText = child.firstChild.data
            elif child.nodeName == "tooltip":
                if len(child.childNodes) > 0:
                    self.tooltip = child.firstChild.data
            elif child.nodeName == "int7":
                self.int7 = int(child.firstChild.data)
            elif child.nodeName == "int8":
                self.int8 = int(child.firstChild.data)
            elif child.nodeName == "int9":
                self.int9 = int(child.firstChild.data)
            elif child.nodeName == "int10":
                self.int10 = int(child.firstChild.data)
            elif child.nodeName == "int11":
                self.int11 = int(child.firstChild.data)   
            elif child.nodeName == "flag7":
                self.flag7 = int(child.firstChild.data)
            elif child.nodeName == "localisationID":
                if len(child.childNodes) > 0:
                    self.localisationID = child.firstChild.data
            elif child.nodeName == "tooltipID":
                if len(child.childNodes) > 0:
                    self.tooltipID = child.firstChild.data
            elif child.nodeName == "font":
                if len(child.childNodes) > 0:
                    self.font = child.firstChild.data
            elif child.nodeName == "int12":
                self.int12 = int(child.firstChild.data)
            elif child.nodeName == "int13":
                self.int13 = int(child.firstChild.data)
            elif child.nodeName == "textAlphaMultiply":
                self.int14 = int(child.firstChild.data)
            elif child.nodeName == "twui":
                if len(child.childNodes) > 0:
                    self.twui = child.firstChild.data
            elif child.nodeName == "int15":
                self.int15 = int(child.firstChild.data)
            elif child.nodeName == "int16":
                self.int16 = int(child.firstChild.data)
            elif child.nodeName == "int17":
                self.int17 = int(child.firstChild.data)
            elif child.nodeName == "flag8":
                self.flag8 = int(child.firstChild.data)
            elif child.nodeName == "flag9":
                self.flag9 = int(child.firstChild.data)
            elif child.nodeName == "flag10":
                self.flag10 = int(child.firstChild.data)
            elif child.nodeName == "normalt0":
                self.normalt0 = child.firstChild.data
            elif child.nodeName == "int18":
                self.int18 = int(child.firstChild.data)
            elif child.nodeName == "int19":
                self.int19 = int(child.firstChild.data)
            elif child.nodeName == "int20":
                self.int20 = int(child.firstChild.data)
            elif child.nodeName == "int21":
                self.int21 = int(child.firstChild.data)
            elif child.nodeName == "stateDescription":
                if len(child.childNodes) > 0:
                    self.stateDescription = child.firstChild.data
            elif child.nodeName == "eventText":
                if len(child.childNodes) > 0:
                    self.eventText = child.firstChild.data
            elif child.nodeName == "tgaUses":
                self.numTGAUses = int(child.attributes.getNamedItem("num").firstChild.data)
                for tgaUseNode in child.childNodes:
                    if tgaUseNode.nodeName == "tgaUse":
                        atgaUse = tgaUse(self.version, self.indent)
                        atgaUse.constructFromNode(tgaUseNode)
                        self.TGAUses.append(atgaUse)
            elif child.nodeName == "int23":
                self.int23 = int(child.firstChild.data)
            elif child.nodeName == "int24":
                self.int24 = int(child.firstChild.data)
            elif child.nodeName == "transitions":
                self.numTransitions = int(child.attributes.getNamedItem("num").firstChild.data)
                for transitionNode in child.childNodes:
                    if transitionNode.nodeName == "transition":
                        atransition = transition(self.version, self.indent)
                        atransition.constructFromNode(transitionNode)
                        self.transitions.append(atransition)

class transition(debuggable_converter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.short1 = 0
        self.int1 = 0
        self.int2 = 0
        self.short2 = 0
        self.int3 = 0
        
    def readFrom(self, handle):
        """
        Reads from a TypeCastReader handle
        """
        self.type = handle.readInt()
        self.id = handle.readInt()
        if self.version >= 39:
          self.short1 = handle.readShort()
          self.int1 = handle.readInt()
          self.int2 = handle.readInt()
        if self.version >= 43:
          self.short2 = handle.readShort()
          self.int3 = handle.readInt()
    
    def writeTo(self, handle):
        """
        Writes to a TypeCastWriter handle
        """
        handle.writeInt(self.type)
        handle.writeInt(self.id)
        if self.version >= 39:
          handle.writeShort(self.short1)
          handle.writeInt(self.int1)
          handle.writeInt(self.int2)
        if self.version >= 43:
          handle.writeShort(self.short2)
          handle.writeInt(self.int3)
        
    def writeToXML(self, handle):
        """
        Writes to a text file handle
        """
        handle.write(
"""%(indent)s<transition>
%(indent+1)s<type>%(type)i</type>
%(indent+1)s<stateIDRef>%(id)i</stateIDRef>
%(indent+1)s<short1>%(short1)i</short1>
%(indent+1)s<int1>%(int1)i</int1>
%(indent+1)s<int2>%(int2)i</int2>
%(indent+1)s<short2>%(short2)i</short2>
%(indent+1)s<int3>%(int3)i</int3>
%(indent)s</transition>
"""%{"indent": "  "*self.indent, "indent+1": "  "*(self.indent+1), "type": self.type, "id": self.id, "short1": self.short1, "short2": self.short2, "int1": self.int1, "int2": self.int2, "int3": self.int3})

    def constructFromNode(self, node):
        """
        Constructs a transition from a transition XML node
        """
        if node.nodeName != "transition":
            raise(Exception("Not a transition node"))
            return 
        
        for child in node.childNodes:
            if child.nodeName == "type":
                self.type = int(child.firstChild.data)
            elif child.nodeName == "stateIDRef":
                self.id = int(child.firstChild.data)
            elif child.nodeName == "short1":
                self.short1 = int(child.firstChild.data)
            elif child.nodeName == "short2":
                self.short2 = int(child.firstChild.data)
            elif child.nodeName == "int1":
                self.int1 = int(child.firstChild.data)
            elif child.nodeName == "int2":
                self.int2 = int(child.firstChild.data)
            elif child.nodeName == "int3":
                self.int3 = int(child.firstChild.data)
    
        
def convertUIToXML(uiFilename, textFilename):
    uiFile = TypeCastReader(open(uiFilename, "rb"))
    
    versionString = uiFile.read(10)
    if versionString[0:7] != b"Version":
        print("Not a UI layout file or unknown file version: "+uiFilename)
        return
    versionNumber = int(versionString[7:10])

    if versionNumber not in [32, 33, 39, 43, 44, 46, 47, 49, 50]:
      print("Version %d not supported" % versionNumber)
      return
    
    outFile = open(textFilename, "w")
    outFile.write("<ui>\n\t<version>%03d</version>\n" % versionNumber)
    
    uiE = uiEntry(versionNumber, 1)
    uiE.readFrom(uiFile)
    uiE.writeToXML(outFile)
    
    outFile.write("</ui>")
    
    uiFile.close()
    outFile.close()
    
def convertXMLToUI(xmlFilename, uiFilename):
    dom = parse(xmlFilename)
    #outFile = TypeCastWriter(open(uiFilename, "wb"))
    versionNode = dom.getElementsByTagName("version")[0]
    version = versionNode.firstChild.nodeValue
    
    rootNode = versionNode.nextSibling.nextSibling
    root = uiEntry(int(version), 0)
    root.constructFromNode(rootNode)
    
    outFile = TypeCastWriter(open(uiFilename, "wb"))
    outFile.write(b'Version'+version.encode())
    root.writeTo(outFile)
    
    outFile.close()

if sys.argv[1] == "-x":
    convertXMLToUI(sys.argv[2], sys.argv[3])
elif sys.argv[1] == "-u":
    convertUIToXML(sys.argv[2], sys.argv[3])
elif sys.argv[1] == "-xa":
    filelist = os.listdir(os.getcwd())
    if not os.path.isdir("./uiOutput"):
        os.mkdir("./uiOutput")
    for filename in filelist:
        if not filename.startswith(".") and not os.path.isdir(filename):
            convertXMLToUI(filename, "./uiOutput/"+filename.split(".")[0])
elif sys.argv[1] == "-ua":
    if not os.path.isdir("./output"):
        os.mkdir("./output")
    filelist = os.listdir(os.getcwd())
    for filename in filelist:
        if not filename.startswith(".") and not os.path.isdir(filename):
            convertUIToXML(filename,"./output/"+filename+".xml")

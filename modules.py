import csv,json 
    
class fileHandler():
    #path=os.path.abspath(__file__)
    path=os.path.abspath(os.getcwd())
    def __init__(self,File):
            self.file=File
    def read(self):
        with open(self.file,'r') as file:
            self.file=file.read()
            return self.file
    def readlines(self):
        with open(self.file,'r') as file:
            self.lines=file.readlines()
            return self.lines
    @classmethod
    def write(cls,filename,path="",*text):
        if not path:
            path=cls.path
        with open(filename,'w') as file:
             file.write(text)
#     @classmethod
#     def writelines(cls,filename,path="",**text):
#         if not path:
#             path=cls.path
#         with  open(filename, "w") as file:
#             file.writelines(text)
#     def append(self,text,path=self.path):
#         with open(self.file,'a') as aFile:
#             aFile.write(text)
#     def appendlines(self,path=self.path,**text):
#         with open(self.file,'a') as aFile:
#             aFile.write(text)
    
    def csvReader(self,delimiter=',',Header=False):
        Z=[z for z in csv.reader(open(self.file))]
        if Header:
            self.Z=Z[1:]
        else:
            self.Z=Z
        return self.Z
    def jsonParser(self):
        self.S=list(map(lambda x: json.loads(x),self.readlines()))
        return self.S
            

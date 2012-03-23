import exceptions

class MergeException(exceptions.Exception):
    def __init__(self, file, message="Merge Failed"):
        self.file = file
        self.message = message
        
    def __str__(self):
        return  self.message + '\n\n' + 'File -> ' + self.file 


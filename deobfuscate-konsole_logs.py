##Copyright (c) 2016 Colin Stevens
##
##Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
##
##The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
##
##THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Assumptions:
#   * konsole-<foo>.history files are in the working directory of the script
#   * The script/user has read access to these files, and write access to the working directory
#   * The user only wants to preserve characters in the ASCII set, and disregard all other bytes
#   * The user wishes for the unobfuscated files to be saved out into the working directory
import os, fnmatch, re

infiles = []
rawFiles = []
parsedFiles = []
keepChars = '0123456789abcdefghijklmnopqrstuvwxyz -_[]()!@#$%^&*=+{};:/?\'"<>,.'

# Create list of files that look like Konsole history
for f in os.listdir('.'):
    if fnmatch.fnmatch(f, 'konsole-*.history'):
        infiles.append(f)
        
# Open history files, fill tuple with every 12th byte
for i in infiles:
    try:
        fileObj = open(i, errors='replace') # Suppresses UnicodeDecodeError for non-ASCII bytes in the stream
        rawFiles.append((fileObj,fileObj.read()[::12]))
    except:
        print("{0} failed.".format(repr(i[0])))
        pass

# Strip non-ASCII bytes from bytestring , strip excess spaces, and place in tuple position [1]
for i in rawFiles:
    try:
        parsedFiles.append((i[0], re.sub(' +',' ',''.join(filter(lambda x: x.lower() in keepChars, i[0])))))
    except:
        print("Error parsing {0}.".format(i[0].name))
        pass


# Write out parsed files as x.unobfuscated
for i in parsedFiles:
    f = open('./{0}.unobfuscated'.format(i[0].name), 'wb')
    f.write(i[1].encode('utf-8'))
    print("Saving {0} as {1}.".format(i[0].name, f.name))
    i[0].close() # Save the python garbage man some work

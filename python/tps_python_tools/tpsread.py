"""
tpsread run script to read in common TPS data
"""

import numpy as np
from sys import exit
import pandas as pd
import re
 
def tpsread(*args):
    read_file, save_to_file = check_files(*args)
    
    last4 = read_file[-4:]
    
    if last4 != 'none':    
        def csv_import(read_file):
            data = pd.read_csv(read_file)
            return data
             
        def xls_import(read_file):
            data = pd.read_excel(read_file)
            return data

        switcher = {
            '.csv': csv_import,
            '.xls': xls_import,
            'xlsx': xls_import
        }
        func = switcher.get(last4, "none")
        
        data = func(read_file)
        data = clean_data(data)
    
        export_csv(save_to_file, data)
        return data
    else:
        return ('Unknown extention %s'%(last4))

def check_files(*args):
    if len([args]) == len([args][0][0]):
        nvargin = 1    
    else:
        nvargin = len(args)
    
    read_file = args[0]    
    last4 = read_file[-4:]
    if nvargin < 2:
        user_confirm = input('You are about to overwrite the file you loaded in. Are you sure you want to proceed? (yes/no): ')
        user_confirm = user_confirm.lower()
        if user_confirm != 'yes':
            exit()
        if last4[0] == '.':
            save_to_file = read_file[:-3] + 'csv'
        else:
            save_to_file = read_file[:-4] + '.csv'
    else:
        save_to_file = args[1]
    return read_file, save_to_file

def clean_data(data):
    headers = list(data.columns.values)
    data.columns = data.columns.str.replace('[#,@,&, ,$,!,^,*,-]','_') 
    cut_data = None
    
    def irig_time(data):
        time = data.IRIG_TIME
        new_time = []
        for i, x in enumerate(time):
            while (x[0] == ' '):
                x = x[1:]
            if (' ' in x) or (':' in x):                
                x = re.split(':| ', x)
                try:
                    sec = float(x[-1])
                    total_time = sec
                    minute = int(x[-2])*60
                    total_time = sec + minute
                    hr = int(x[-3])*3600
                    total_time = sec + minute + hr
                    day = int(x[-4])*24*3600
                    total_time = sec + minute + hr + day
                except:
                    pass
            else:
                sec = float(x[-1])
                total_time = sec
            new_time.append(total_time)
        data['Time'] = new_time
        delta_time_total = 0
        if 'Delta_Irig' in headers:
            delta_irig = data.Delta_Irig
            for i, x in enumerate(delta_irig):
                if i == (len(delta_irig)-1):
                    break
                delta_time_total += delta_irig[i+1] - x
            delta_time = delta_time_total/len(delta_irig) * 2
            for i, x in enumerate(delta_irig):
                if i == len(delta_irig):
                    break
                if (delta_time < (delta_irig[i+1] - x)):
                    cut_data = i + 1
                    return data, cut_data
        return data, cut_data
        
    for heading in headers:
        switcher = {
            'IRIG_TIME': irig_time
            }  
        try:
            func = switcher.get(heading, "none")
            data, cut_data = func(data)
        except:
            pass
   
    if 'Time' in data:
        headers.insert(0, 'Time')
        data = data[headers] 
        
    if (cut_data != None):
        data = data[cut_data:]
        data = data.reset_index()
        data.drop('index', axis=1, inplace=True)
    for heading in headers:
        if (heading != 'IRIG_TIME'):
            head = list(data[heading].copy())
            for i, x in enumerate(head):
                if type(x) == str:
                    try:
                        x = float(x)
                    except:
                        pass
                if (type(x) == str):
                    head[i] = None
            data[heading] = head
    data = data.replace({np.nan: None})
    return data
    
def export_csv(save_to_file, data):
    data.to_csv(save_to_file, index=False)

if __name__ == "__main__":
    user_read_file = ''
    while len(user_read_file) == 0:
        user_read_file = str(input('Enter the file to be read, include the file extention: '))
        if (len(user_read_file) <= 4 
            or (user_read_file[-4:] != '.csv' 
            and user_read_file[-4:] != '.xls'
            and user_read_file[-5:] != '.xlsx')):
            print('File %s is not valid. The file must end in .csv, .xls, or .xlsx.'%(user_read_file))
            user_read_file = ''
        else:
            pass
     
    user_save_to_file = ''
    while len(user_save_to_file) == 0:    
        user_save_to_file = str(input('WARNING .csv FILE WILL BE OVERWRITTEN IF LEFT BLANK. Enter name for new file, include the file extention: '))
        if len(user_save_to_file) != 0:
            if (len(user_save_to_file) <= 4 or user_save_to_file[-4:] != '.csv'):
                print('File %s is not valid. The file name must end in .csv'%(user_save_to_file))
                user_save_to_file = ''
            else:
                pass
        else:
            break 
    
    if len(user_save_to_file) != 0:
        data = tpsread(user_read_file, user_save_to_file)
    else:
        data = tpsread(user_read_file)
    
data = tpsread(user_read_file, user_save_to_file)
    


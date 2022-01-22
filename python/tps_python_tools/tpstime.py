import re

example_run = False

def irig_time(time, num_dec=None):
    
    """irig_time converts IRIG_TIME to seconds and seconds to IRIG time.
    
    Positional Arguments:
    time -- Enter as a string, list, float, integer, pandas.core.series.Series, 
        and numpy.float64. Additional data types may work. Inputs can either 
        be IRIG time or seconds. irig_time will recognize strings as irig_time 
        and will convert to seconds.(required positional argument)
    num_sig -- Enter as an integer. Defines how many decimal places to round 
        time to. Default is three. (optional positional argument)
        
    Example:
    example_run -- When 'example_run = True' four examples with four time 
        inputs will run"""
    
    if type(time) != str:
        try: 
            len(time)
            time = list(time)
        except:
            time = float(time)
    if num_dec == None:
        num_dec = 3
    if type(time) == float:
        day =  time // 86400
        hrs = (time - day*86400) // 3600
        minute = (time - day*86400 - hrs*3600) // 60
        sec = time - day*86400 - hrs*3600 - minute*60   
        time_list = [day, hrs, minute]
        for i, x in enumerate(time_list):
            x = str(int(x))
            if len(x) < 2:
                time_list[i] = '0' + x + ':'
            else:
                time_list[i] = x + ':'
        sec = round(sec, num_dec) 
        if len(str(sec // 1)) < 4:
            sec = '0' + str(sec)
        else:
            sec = str(sec) 
        return ''.join(time_list) + sec

    if type(time) == str:
        time = list(time)
        time = ''.join(time)
        if (' ' in time) or (':' in time):                
            time = re.split(':| ', time)
            try:
                sec = round(float(time[-1]), num_dec)
                total_time = sec
                minute = int(time[-2]) * 60
                total_time = sec + minute
                hr = int(time[-3]) * 3600
                total_time = sec + minute + hr
                day = int(time[-4]) * 24 * 3600
                total_time = sec + minute + hr + day
            except:
                pass
        else:
            sec = round(float(time), num_dec)
            total_time = sec
        return total_time

    if type(time[0]) == float:
        total_time_irig = []
        for i, x in enumerate(time):
            day =  x // 86400
            hrs = (x - day*86400) // 3600
            minute = (x - day*86400 - hrs*3600) // 60
            sec = x - day*86400 - hrs*3600 - minute*60  
            time_list = [day, hrs, minute]
            for i, x in enumerate(time_list):
                x = str(int(x))
                if len(x) < 2:
                    time_list[i] = '0' + x + ':'
                else:
                    time_list[i] = x + ':'
            sec = round(sec, num_dec)
            if len(str(sec // 1)) < 4:
                sec = '0' + str(sec)
            else:
                sec = str(sec)
            total_time_irig.append(''.join(time_list) + sec)
        return total_time_irig

    if type(time[0]) == str:    
        new_time = []
        for i, x in enumerate(time):
            while (x[0] == ' '):
                x = x[1:]
            if (' ' in x) or (':' in x):                
                x = re.split(':| ', x)
                try:
                    sec = round(float(x[-1]), num_dec)
                    total_time = sec
                    minute = int(x[-2]) * 60
                    total_time = sec + minute
                    hr = int(x[-3]) * 3600
                    total_time = sec + minute + hr
                    day = int(x[-4]) * 24 * 3600
                    total_time = sec + minute + hr + day
                except:
                    pass
            else:
                sec = round(float(x), num_dec)
                total_time = sec
            new_time.append(total_time)
    return new_time

#Example
if example_run:
    time_1 = '43:16:45:21.45261'
    time_2 = [
        '43:16:45:22.44261',
        '43:16:45:23.45261',
        '43:16:45:24.46261',
        '43:16:45:25.47261',
        '43:16:45:26.48261'
        ]
    time_3 = '45454546.4361'
    time_4 = [
        5123646.4361,
        5123649.5361,
        5123654.6361,
        5153646.8361,
        5523646.3361
        ]
    single_irig = irig_time(time_1, 3) # Returns irig time in seconds.
    list_irig = irig_time(time_2, 2) # Returns irig time in seconds.
    singel_second = irig_time(time_3) # Returns seconds in irig time.
    list_second = irig_time(time_4, 3) # Returns seconds in irig time.
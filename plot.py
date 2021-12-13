import sys
import pandas as pd
import matplotlib.pyplot as plt

run_example = False

def tps_title(
        big_title=None,
        col_text=None,
        axis_label=None,
        fonts=None,
        file_name=None):

    """tps_title creates a standard TPS plot

    Function arguments should be entered as keyword arguments
    
    Keyword arguments:
    big_title -- Enter as a string (required keyword)
    col_text -- Enter as a list of lists. Each list in the list of lists is 
        one column. (required keyword)
    axis_label -- Enter as a list of strings. First string is the x-axis. 
        Second string is the y-axis. (required keyword)
    fonts -- Enter as a list of two numbers. Font size should 
        be entered in points. The first value is the font of big_title. The 
        second value is the font of all other text. (optional keyword)
    file_name -- Saves plot as a .png. Enter as a string. Must end
        in '.png'. (optional keyword)
        
    Example:
    example_run -- When 'example_run = True' an example plot will be displayed 
        and saved to the .png file named 'myplot.png'."""
    
    if (big_title == None or col_text == None or axis_label == None):
        print('big_title, col_text, and axis_label are required arguments')
        sys.exit()
    if (type(big_title) != str):
        print('big_title must be a string')
        sys.exit()
    if (type(col_text) != list or type(col_text[0]) != list):
        print('col_text must be a list of lists even if there is only one column')
        sys.exit()
    if (len(axis_label) != 2 or type(axis_label) != list or 
        type(axis_label[0]) != str or type(axis_label[1]) != str):
        print('axis_label must be a list of two strings')
        sys.exit()
    if (len(fonts) != 2 or type(fonts) != list):
        print('fonts must be a list of two numbers')
        sys.exit()        

    if fonts == None:
        big_font = 12
        col_font = 10
    else:
        big_font = fonts[0]
        col_font = fonts[1]
    
    num_cols = len(col_text)
    col_lengths = []
    for columns in col_text:
        col_lengths.append(len(columns))
    num_rows = max(col_lengths)
        
    for x in range(0, num_cols):
        for j in range(0, num_rows+1):
            try: 
                col_text[x][j]
            except:
                col_text[x].append('')
    data={}
    for x in range(0, num_cols):
        data[x] = col_text[x]            
    col_text_pd = pd.DataFrame(data)     
    
    plt.xlabel(axis_label[0], fontsize = col_font)
    plt.ylabel(axis_label[1], fontsize = col_font)
    plt.xticks(fontsize = col_font)
    plt.yticks(fontsize = col_font)
    plt.rc('font', size = col_font)
    
    table_data = plt.table(
        cellText = col_text_pd.values,
        cellLoc = 'left', 
        rowLoc = 'left',
        loc='top',
        edges='open'
        )
    table_data.auto_set_column_width(col = list(range(len(col_text_pd.columns))))
    cell_dict = table_data.get_celld()
    for i in range(0, num_cols):
        for j in range(0, num_rows):
            cell_dict[(j, i)].set_height(col_font / 216)      
            
    plt.title(
        big_title, 
        pad = (col_font * (num_rows + 2)), 
        fontsize = big_font
        ) 
        
    if (file_name == None):
        sys.exit()
    elif (file_name[-4:] == '.png'):
        plt.savefig(file_name, dpi = 600, bbox_inches="tight")
    else:
        print("%s is not a valid file name. Must be a string and end in '.png'." %(file_name))
        
    plt.show()

# Example
if run_example == True:
    x = ([1,14])
    y = ([1,10])
    plt.plot(x, y)
    big_title = ('Gilbert XF-20')
    col_text = [
        ['Configuration: Cruise', 
        'Pressure Altitude: 10,000 feet',
        'Weight: 57,000 pounds', 
        'CG: 23.9 percent',
        r'Wing Reference Area: 548 $ft^{ 2}$'],
        ['Data Basis: Flight Test',
        'Test Dates: 2 Sep 50',
        'Test Day Data',
        r'W/$\delta$ = 82,884 pounds']
        ]
    axis_label = [
        r'Angle of Attack, $\alpha (deg)$', 
        r'Lift Coefficient, $C_{L}$'
        ]
    fonts = [25, 18]
    file_name = 'myplot.png'
    
    tps_title(
        big_title=big_title,
        col_text=col_text,
        axis_label=axis_label,
        fonts=fonts,
        file_name=file_name)
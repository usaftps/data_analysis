% Example function shell
%
% This script demonstrates a basic matlab function with two inputs and two
% outputs. Feel free to change the name, number of inputs, and number of 
% outputs as necessary. Be sure to change the name of the file to match the
% name of the function.
%
% As long as this file is in your Matlab path and the filename matches the
% function name (i.e., example_function is contained in the file
% example_function.m) then you can call this function from any other
% script.
function [output1, output2] = example_function(input1,input2)
    % Use inputs to do something
    variable1 = input1 + input2;
    variable2 = input1*input2;
    
    % Set output values
    output1 = variable1;
    output2 = variable2;
end
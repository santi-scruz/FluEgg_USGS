%%%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                       Edit or import FluEgg River Input data           %
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%-------------------------------------------------------------------------%
% This function is used to import river input data into FluEgg. Currently %
% there are two options, import an excel, csv or text file, or import a   %
% steady or unsteady state HEC-RAS project.                                %
%-------------------------------------------------------------------------%
%                                                                         %
%-------------------------------------------------------------------------%
%   Created by      : Tatiana Garcia                                      %
%   Last Modified   : May 9, 2016                                         %
%-------------------------------------------------------------------------%
% Inputs: River input file (xls,xlsx,csv,txt) or HEC-RAS project (prj)    %
%        river input file containing cell number,cumulative distance, flow,
%        velocity magnitude, Vy, Vz, shear velocity, water depth,water    %
%        temperature.
% Outputs: FluEgg River input file(s)
% Copyright 2016 Tatiana Garcia
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%

function varargout = Edit_River_Input_File(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Edit_River_Input_File_OpeningFcn, ...
                   'gui_OutputFcn',  @Edit_River_Input_File_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

function Edit_River_Input_File_OpeningFcn(hObject, ~, handles, varargin)
ScreenSize=get(0, 'screensize');
set(handles.River_inputfile_GUI,'Position',[1 1 ScreenSize(3:4)])
%Logs erros in a log file
diary('./results/FluEgg_LogFile.txt')
handles.output = hObject;
guidata(hObject, handles);
end

function varargout = Edit_River_Input_File_OutputFcn(~,~, handles) 
diary off
varargout{1} = handles.output;
% if the user suppled an 'exit' argument, close the figure by calling
% figure's CloseRequestFcn
if (isfield(handles,'closeFigure') && handles.closeFigure)
    Edit_River_Input_File_CloseRequestFcn(hObject, eventdata, handles)
end
end

% function pannel_CreateFcn(~, ~, ~)
% delete(hObject);
% end

function Riverinput_filename_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
%% <<<<<<<<<<< USER WANTS TO IMPORT A SINGLE RIVER INPUT FILE >>>>>>>>>>>%%

function loadfromfile_Callback(hObject,~, handles)
%%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
[FileName,PathName]=uigetfile({'*.*',  'All Files (*.*)';
   '*.xls;*.xlsx'     , 'Microsoft Excel Files (*.xls,*.xlsx)'; ...
   '*.csv'             , 'CSV - comma delimited (*.csv)'; ... 
    '*.txt'             , 'Text (Tab Delimited (*.txt)'}, ...
    'Select file to import');
strFilename=fullfile(PathName,FileName);
if PathName==0 %if the user pressed cancelled, then we exit this callback
    return
else
    if FileName~=0
        % Load River input file
        m=msgbox('Please wait, loading file...','FluEgg');
        set(handles.Riverinput_filename,'string',fullfile(FileName));
        extension=regexp(FileName, '\.', 'split');
        if (strcmp(extension(end),'xls') == 1 || strcmp(extension(end),'xlsx') == 1)
            %% If xlsread fails
            try %Eddited TGB 03/21/14
                [Riverinputfile, Riverinputfile_hdr] = xlsread(strFilename); 
                close(m);
            catch
                close(m);
                m=msgbox('Unexpected error, please try again','FluEgg error','error');
                uiwait(m)
                return
            end
            %%
        elseif strcmp(extension(end),'csv') == 1%|| strcmp(extension(end),'txt') == 1
            Riverinputfile=importdata(strFilename);   
            Riverinputfile_hdr=Riverinputfile.textdata;
            Riverinputfile=Riverinputfile.data;
            close(m);
        elseif strcmp(extension(end),'txt') == 1
            Riverinputfile=importdata(strFilename);
            if  isstruct(Riverinputfile)
                Riverinputfile_hdr=Riverinputfile.textdata; 
                Riverinputfile_hdr=regexp(Riverinputfile_hdr, '\t', 'split');
                Riverinputfile_hdr=Riverinputfile_hdr{1,1};
                Riverinputfile=Riverinputfile.data;
            else
                ed = errordlg('Please fill all the data required in the river input file, and load the file again','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);
                close(m)
                return
            end
            close(m)
            %%
        else
            msgbox('The file extension is unrecognized, please select another file','FluEgg Error','Error');
            return
        end %Checking file extension
        try
            handles.userdata.Riverinputfile=Riverinputfile(:,1:9); 
            handles.userdata.Riverinputfile_hdr=Riverinputfile_hdr(:,1:9);
            if size(Riverinputfile_hdr)~=[1 9]
                ed = msgbox('Incorrect river input file, please select another file','FluEgg Error','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);
                return
            elseif sum(strcmp(Riverinputfile_hdr(:,1:9),{'CellNumber','CumlDistance_km','Depth_m','Q_cms','Vmag_mps','Vvert_mps','Vlat_mps','Ustar_mps','Temp_C'}))<9
                ed = msgbox('Incorrect river input file, please select another file','FluEgg Error','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);
                return
            end
            set(handles.RiverInputFile,'Data',handles.userdata.Riverinputfile(:,1:9));
            Riverin_DataPlot(handles);
        catch
            if size(Riverinputfile,2) ~= 9
                ed = errordlg('Please fill all the data required in the river input file, and load the file again','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);
                return
            end
        end %try
    end
end %if user pres cancel
guidata(hObject, handles);% Update handles structure
end % end function loadfromfile_Callback

function [ks]=Ks_calculate(handles,VX)
%% Input data needed to calculate ks
	Riverinputfile=handles.userdata.Riverinputfile;
	Depth=Riverinputfile(:,3);        %m
	%Vmag=Riverinputfile(:,5);         %m/s
	%Vlat=Riverinputfile(:,6);         %m/s
	%Vvert=Riverinputfile(:,7);        %m/s
	Ustar=Riverinputfile(:,8);        %m/s
%%
	%VX=sqrt(Vmag.^2-Vlat.^2-Vvert.^2);%m/s
	ks=11*Depth./exp((VX.*0.41)./Ustar);%m
end

%%:::::PLOT INPUT DATA:::::::::::::::::::::::::::::::::::::::::::::::::::::
function Riverin_DataPlot(handles)
%% DepthPlot Riverin data
Riverinputfile=handles.userdata.Riverinputfile;
%calculate cumulative distance as the middle of the cell
x=Riverinputfile(:,2);
x=[(x+[0; x(1:end-1)])/2; x(end)];
%% Depth
set(handles.DepthPlot,'Visible','on');
plot(handles.DepthPlot,x,[Riverinputfile(:,3);Riverinputfile(end,3)],'LineWidth',1.5,'Color',[0 0 0]); 
ylabel(handles.DepthPlot,'H [m]','FontWeight','bold','FontSize',10);
box(handles.DepthPlot,'on');

xlim(handles.DepthPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================
%% QPlot Riverin data
set(handles.QPlot,'Visible','on');
plot(handles.QPlot,x,[Riverinputfile(:,4);Riverinputfile(end,4)],'LineWidth',1.5,'Color',[0 0 0]);
ylabel(handles.QPlot,{'Q [cms]'},'FontWeight','bold','FontSize',10);
box(handles.QPlot,'on'); 

xlim(handles.QPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================
%% VmagPlot Riverin data
set(handles.VmagPlot,'Visible','on');
plot(handles.VmagPlot,x,[Riverinputfile(:,5);Riverinputfile(end,5)],'LineWidth',1.5,'Color',[0 0 0]);
ylabel(handles.VmagPlot,{'Vmag [m/s]'},'FontWeight','bold','FontSize',10);
box(handles.VmagPlot,'on');
xlim(handles.VmagPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================
%% VyPlot Riverin data
set(handles.VyPlot,'Visible','on');
plot(handles.VyPlot,x,[Riverinputfile(:,6);Riverinputfile(end,6)],'LineWidth',1.5,'Color',[0 0 0]);
ylabel(handles.VyPlot,{'Vy [m/s]'},'FontWeight','bold','FontSize',10);
box(handles.VyPlot,'on');%check
xlim(handles.VyPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================
%% VzPlot Riverin data
set(handles.VzPlot,'Visible','on');
plot(handles.VzPlot,x,[Riverinputfile(:,7);Riverinputfile(end,7)],'LineWidth',1.5,'Color',[0 0 0]);
ylabel(handles.VzPlot,{'Vz [m/s]'},'FontWeight','bold','FontSize',10);
box(handles.VzPlot,'on');
xlim(handles.VzPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================
%% UstarPlot Riverin data
set(handles.UstarPlot,'Visible','on');
plot(handles.UstarPlot,x,[Riverinputfile(:,8);Riverinputfile(end,8)],'LineWidth',1.5,'Color',[0 0 0]); 
ylabel(handles.UstarPlot,{'u_* [m/s]'},'FontWeight','bold','FontSize',10);
xlabel(handles.UstarPlot,{'Cumulative distance [Km]'},'FontWeight','bold',...
    'FontSize',10);
box(handles.UstarPlot,'on');
% axis(handles.UstarPlot,[0 max(Riverinputfile(:,2)) 0 max(Riverinputfile(:,8))*1.5]);
xlim(handles.UstarPlot,[0 max(Riverinputfile(:,2))]);
%==========================================================================

%% TempPlot Riverin data
set(handles.TempPlot,'Visible','on');
plot(handles.TempPlot,x,[Riverinputfile(:,9);Riverinputfile(end,9)],'LineWidth',1.5,'Color',[0 0 0]); 
ylabel(handles.TempPlot,{'T [^oC]'},'FontWeight','bold','FontSize',10);
xlabel(handles.TempPlot,{'Cumulative distance [Km]'},'FontWeight','bold', 'FontSize',10);
box(handles.TempPlot,'on');
xlim(handles.TempPlot,[0 max(Riverinputfile(:,2))]);

%==========================================================================
end

function RiverInputFile_CellEditCallback(hObject, eventdata, handles)
if  isfield(handles,'userdata')==0
   ed = errordlg('Please load the river input file and continue','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
handles.userdata.Riverinputfile=get(handles.RiverInputFile,'Data');
guidata(hObject, handles);% Update handles structure
Riverin_DataPlot(handles)
end

function RiverInputFile_CellSelectionCallback(~, eventdata, handles)
end

function ContinueButton_Callback(hObject, eventdata, handles)
if  isfield(handles,'userdata')==0
   ed = errordlg('Please load the river input file and continue','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
%% Load data for code audit
%===========================================================================================
Riverinputfile=handles.userdata.Riverinputfile;

% Create hydraulic variables
CumlDistance = Riverinputfile(:,2);   %Km
Depth = Riverinputfile(:,3);          %m
Q = Riverinputfile(:,4);              %m3/s
Vmag = Riverinputfile(:,5);           %m/s
Vlat = Riverinputfile(:,6);           %m/s
Vvert = Riverinputfile(:,7);          %m/s
Ustar = Riverinputfile(:,8);          %m/s
%==========================================================================
%% Error  %Code audit 03/2015 TG
if  any(CumlDistance<=0)
   ed = errordlg('Invalid negative or zero value for attribute cumulative distance','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
if  any(Depth<=0)
   ed = errordlg('Invalid negative or zero value for attribute depth','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
if  any(Vmag<0)
   ed = errordlg('Invalid negative value for attribute velocity magnitud','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
if  any(Vmag==0)
   ed = errordlg('Invalid zero value for attribute velocity magnitud. You may use a very small value for Vmag, but it still must be greater than zero.','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
if  any(Ustar<0)
   ed = errordlg('Invalid negative value for attribute shear velocity','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
if  any(Vmag==0)
   ed = errordlg('Invalid zero value for attribute shear velocity. You may use a very small value for Ustar, but it still must be greater than zero.','Error');
   set(ed, 'WindowStyle', 'modal');
   uiwait(ed); 
   return
end
%==========================================================================
%%
Width=abs(Q./(Vmag.*Depth));           %m
VX=sqrt(Vmag.^2-Vlat.^2-Vvert.^2);%m/s
ks=Ks_calculate(handles,VX);
handles.userdata.Riverinputfile=[ handles.userdata.Riverinputfile ks]; 
%%
temp_variables.CumlDistance=CumlDistance;
temp_variables.Depth=Depth;
temp_variables.Q=Q;
temp_variables.VX=VX;
temp_variables.Vlat=Vlat;
temp_variables.Vvert=Vvert;
temp_variables.Ustar=Ustar;
temp_variables.Temp=Riverinputfile(:,9);         %C
temp_variables.ks=ks;  
temp_variables.Width=Width;
save './Temp/temp_variables.mat' 'temp_variables'

%=========================================================================
%% Updating spawning location to the middle of the cell
   %% getting main handles
   hFluEggGui=getappdata(0,'hFluEggGui');
   handlesmain=getappdata(hFluEggGui, 'handlesmain');
   %If user input data, autopopulate lateral position of spawning location
   set(handlesmain.Yi_input,'String',floor(Width(1)*100/2)/100);
   guidata(hObject, handles);% Update handles structure

%=========================================================================
%% Updating River Geometry Summary
set(handlesmain.MinX,'String',floor(min(CumlDistance)*10)/10);
set(handlesmain.MaxX,'String',floor(max(CumlDistance)*10)/10);
set(handlesmain.MinW,'String',floor(min(Width)*10)/10);
set(handlesmain.MaxW,'String',floor(max(Width)*10)/10);
set(handlesmain.MinH,'String',floor(min(Depth)*10)/10);
set(handlesmain.MaxH,'String',floor(max(Depth)*10)/10);
diary off
close();
end

function SaveFile_button_Callback(hObject, eventdata, handles)
[file,path] = uiputfile('*.txt','Save modified file as');
strFilename=fullfile(path,file);
if ~isfield(handles,'userdata')%Eddited TGB 03/21/14
    handles.userdata=[];
    handles.userdata.Riverinputfile=get(handles.RiverInputFile,'Data');
    handles.userdata.Riverinputfile_hdr=get(handles.RiverInputFile,'ColumnName');
end
hdr=handles.userdata.Riverinputfile_hdr;
dlmwrite(strFilename,[sprintf('%s\t',hdr{:}) ''],'');
dlmwrite(strFilename,get(handles.RiverInputFile,'Data'),'-append','delimiter','\t','precision', 6);
end

function tools_ks_Callback(hObject, eventdata, handles)
end

%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%

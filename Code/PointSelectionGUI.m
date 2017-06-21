function varargout = PointSelectionGUI(varargin)
% POINTSELECTIONGUI MATLAB code for PointSelectionGUI.fig
%      POINTSELECTIONGUI, by itself, creates a new POINTSELECTIONGUI or raises the existing
%      singleton*.
%
%      H = POINTSELECTIONGUI returns the handle to a new POINTSELECTIONGUI or the handle to
%      the existing singleton*.
%
%      POINTSELECTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POINTSELECTIONGUI.M with the given input arguments.
%
%      POINTSELECTIONGUI('Property','Value',...) creates a new POINTSELECTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PointSelectionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PointSelectionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PointSelectionGUI

% Last Modified by GUIDE v2.5 21-Jun-2017 15:41:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PointSelectionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PointSelectionGUI_OutputFcn, ...
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


% --- Executes just before PointSelectionGUI is made visible.
function PointSelectionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PointSelectionGUI (see VARARGIN)

% handles.outout = hObject;

% Accept Settings from MainGUI or Load Settings.mat
if isempty(varargin)
    stemp=load('Settings.mat');
    Settings = stemp.Settings;
    clear stemp
    handles.MainGUI = [];
else
    if length(varargin) == 2
        handles.Fast = varargin{2};
    end
    handles.MainGUI = varargin{1};
    MainHandle = guidata(handles.MainGUI);
    Settings = MainHandle.Settings;
end

% Excecute HREBSDPrep
if ~isfield(Settings,'HREBSDPrep') || ~Settings.HREBSDPrep
    Settings = HREBSDPrep(Settings);
    if ~isempty(handles.MainGUI) && isvalid(handles.MainGUI)
        MainHandles = guidata(handles.MainGUI);
        MainHandles.Settings = Settings;
        guidata(MainHandles.MainGUI,MainHandles);
    end
end
handles.Settings = Settings;

% Set Max Blink Speed
handles.MaxSpeed = 4;

% Load previous settings
if exist('SystemSettings.mat','file')
    load SystemSettings.mat
end
if ~exist('TestGeometrySettings','var')
   TestGeometrySettings.blinkspeed = 'Medium';
   TestGeometrySettings.color = 'green';
   TestGeometrySettings.MapType = 'Image Quality';
   TestGeometrySettings.LineWidth = 0.5;
end

% Populate Color Dropdown
ColorString = {'yellow','magenta','cyan','red','green','blue','white','black','holiday'};
set(handles.ColorScheme,'String',ColorString);
SetPopupValue(handles.ColorScheme,TestGeometrySettings.color);

% Set Blink Speed
SpeedOptions = {'No Blink','Slow','Medium','Fast','Hide Bands'};
set(handles.BlinkSpeed,'String',SpeedOptions);
SetPopupValue(handles.BlinkSpeed,TestGeometrySettings.blinkspeed);

% Set Line Width
LineOptions = {'Thin','Medium','Thick'};
set(handles.LineWidth,'String',LineOptions);
SetPopupValue(handles.LineWidth,TestGeometrySettings.LineWidth);

% Set Number of Families (off until a point is selected)
set(handles.NumFam,'Enable','off');
set(handles.NumFam,'String','4');

% Set Map Type
if strcmp(TestGeometrySettings.MapType,'Image Quality')
    set(handles.IQMap,'Value',1)
else
    set(handles.IPFMap,'Value',1)
end

% Simulated Pattern Type
set(handles.SimType,'String',{'Simulated','Dynamic'})
if strcmp(Settings.HROIMMethod,'Dynamic Simulated')
    SimType = 'Dynamic';
else
    SimType = 'Kinematic';
end
SetPopupValue(handles.SimType,SimType);

% Turn off GB's by default
set(handles.PlotGB,'Value',0)

% Filter by default
set(handles.Filter,'Value',1)

% Generate Index arrays
n = Settings.Nx; m = Settings.Ny;
if strcmp(Settings.ScanType,'Square')
    indi = 1:1:m*n;
    indi = reshape(indi,n,m)';
elseif strcmp(Settings.ScanType,'Hexagonal')
    NumColsOdd = n;
    indi = 1:length(Settings.Inds);
    indi = Hex2Array(indi,NumColsOdd);
end
handles.indi = indi;
handles.ind = 0;
handles.refInd = 0;

% Load plots into handles
g = euler2gmat(Settings.Angles);
handles.IPF = PlotIPF(g,[n m],Settings.ScanType,0);
if strcmp(Settings.ScanType,'Square')
    handles.IQ = reshape(Settings.IQ,n,m)';
    handles.CI = reshape(Settings.CI,n,m)';
elseif strcmp(Settings.ScanType,'Hexagonal')
    handles.IQ = Hex2Array(Settings.IQ,n);
    handles.CI = Hex2Array(Settings.CI,n);
end
handles.g = g;
    
% Plot Map
% handles.doPlotPoints = false;
MapSelection_SelectionChangedFcn(handles.MapSelection, eventdata, handles)

% Set Position
if ~isempty(handles.MainGUI) && isvalid(handles.MainGUI)
    MainSize = get(handles.MainGUI,'Position');
    set(hObject,'Units','pixels');
    GUIsize = get(hObject,'Position');
    set(hObject,'Position',[MainSize(1)+MainSize(3)+20 MainSize(2)-(GUIsize(4)-MainSize(4))+26 GUIsize(3) GUIsize(4)]);
    movegui(hObject,'onscreen');
end
gui = findall(handles.PointSelectionGUI,'KeyPressFcn','');
set(gui,'KeyPressFcn',@PointSelectionGUI_KeyPressFcn);

% Plot Pattern Prompt
axes(handles.Pattern)
text(0.5,0.5,{'Select a pattern by clicking'; 'a point on the map to the left'},'HorizontalAlignment','center')
axis off
axes(handles.ReferencePattern)
text(0.5,0.5,{'Select a pattern by clicking'; 'a point on the map to the left'},'HorizontalAlignment','center')
axis off

% Plot GBs on seperate invisible axis
axes(handles.GrainMap); axis image
h = hggroup;
PlotGBs(handles.Settings.grainID,[handles.Settings.Nx handles.Settings.Ny],handles.Settings.ScanType);
lines = findobj('Type','Line');
set(lines,'Parent',h);
h.Visible = 'Off';

% Set up Points axis
axes(handles.Points)
axis image
handles.Points.XLim = handles.Map.XLim;
handles.Points.YLim = handles.Map.YLim;

% Choose default command line output for PointSelectionGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PointSelectionGUI wait for user response (see UIRESUME)
%uiwait(handles.PointSelectionGUI);


% --- Outputs from this function are returned to the command line.
function varargout = PointSelectionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when user attempts to close PointSelectionGUI.
function PointSelectionGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to PointSelectionGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);

% --- Executes on button press in close.
function close_Callback(hObject, eventdata, handles)
% hObject    handle to close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PointSelectionGUI_CloseRequestFcn(handles.PointSelectionGUI, eventdata, handles)

% --- Executes on button press in SaveClose.
function SaveClose_Callback(hObject, eventdata, handles)
% hObject    handle to SaveClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TestGeometrySettings.blinkspeed = GetPopupString(handles.BlinkSpeed);
TestGeometrySettings.color = GetPopupString(handles.ColorScheme);
TestGeometrySettings.LineWidth = GetPopupString(handles.LineWidth);
if get(handles.IPFMap,'Value')
    TestGeometrySettings.MapType = 'IPF';
else
    TestGeometrySettings.MapType = 'Image Quality';
end
save('SystemSettings.mat','TestGeometrySettings','-append')
PointSelectionGUI_CloseRequestFcn(handles.PointSelectionGUI, eventdata, handles)


% --- Executes when selected object is changed in MapSelection.
function MapSelection_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in MapSelection 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.Map)

% Plot Map
if get(handles.IPFMap,'Value')
    PlotScan(handles.IPF,'IPF');
elseif handles.IQMap.Value
    PlotScan(handles.IQ,'IQ');
else
    PlotScan(handles.CI,'CI');
end

axis off
if ~handles.IPFMap.Value
    h = colorbar;
    h.Position(1) = 1 - h.Position(3);
    h.AxisLocation = 'in';
end
uistack(handles.GrainMap, 'top')
uistack(handles.Points, 'top')

% --- Executes on mouse press over axes background.
function Map_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to Map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse motion over figure - except title and menu.
function PointSelectionGUI_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to PointSelectionGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'Settings')
    pt = get(handles.Map,'currentpoint');
    rows = handles.Settings.Nx+0.5;
    cols = handles.Settings.Ny+0.5;
    if handles.Settings.Ny == 1
        cols = round(rows/6);
    end
    handles.overicon =  (pt(1,1)>=0.5 && pt(1,1)<=rows) && (pt(1,2)>=0.5 && pt(1,2)<=cols); 
    if ~handles.overicon
        set(handles.PointSelectionGUI,'pointer','arrow');
    else
        set(handles.PointSelectionGUI,'pointer','crosshair');
    end
    guidata(hObject,handles);
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function PointSelectionGUI_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to PointSelectionGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.overicon
    if handles.ind == 0
        set(handles.NumFam,'UserData',true);
    end
    Settings = handles.Settings;
    n = Settings.Nx; m = Settings.Ny;
    
    % Get Selected Location
    pt = get(handles.Map,'currentpoint');
    x = round(pt(1,1));
    if m == 1
        y = 1;
    else
        y = round(pt(1,2));
    end
    handles.ind = handles.indi(y,x);
    handles.IndexNumEdit.String = num2str(handles.ind);
    guidata(hObject,handles);
    PlotPattern(handles);
end
        

function PlotPattern(handles)
ind = handles.ind;
Settings = handles.Settings;

% Update NumFam Popup
Material = ReadMaterial(Settings.Phase{ind});
Options = strsplit(num2str(1:length(Material.Fhkl)));
set(handles.NumFam,'String',Options);
if strcmp(Material.lattice,'cubic') %Decide how many bands to overlay
    numfamdef = 4;
else
    numfamdef = 5;
end
% Initialization
if get(handles.NumFam,'UserData')
    set(handles.NumFam,'Value',numfamdef);
    set(handles.NumFam,'UserData',false);
    set(handles.NumFam,'Enable','on');
end
% For difference phases
if get(handles.NumFam,'Value') > length(Options)
    set(handles.NumFam,'Value',numfam);
end

% Get variables for the point
xstar = Settings.XStar(ind);
ystar = Settings.YStar(ind);
zstar = Settings.ZStar(ind);
Av = Settings.AccelVoltage*1000; %put it in eV from KeV
sampletilt = Settings.SampleTilt;
elevang = Settings.CameraElevation;
pixsize = Settings.PixelSize;
numfam = get(handles.NumFam,'Value');
mperpix = Settings.mperpix;
paramspat={xstar;ystar;zstar;pixsize;Av;sampletilt;elevang;Material.Fhkl(1:numfam);Material.dhkl(1:numfam);Material.hkl(1:numfam,:)};
g = handles.g(:,:,ind);
phase = Settings.Phase{ind};

% Update GUI Info Box
set(handles.PhaseText,'String',phase)
set(handles.IndexText,'String',num2str(ind))
set(handles.LatticeText,'String',Material.lattice)
set(handles.CIText,'String',Settings.CI(ind))
set(handles.FitText,'String',Settings.Fit(ind))
set(handles.IQText,'String',Settings.IQ(ind))
set(handles.GrainText,'String',Settings.grainID(ind))
set(handles.phi1Text,'String',Settings.Angles(ind,1))
set(handles.PHIText,'String',Settings.Angles(ind,2))
set(handles.phi2Text,'String',Settings.Angles(ind,3))
[~,name,ext] = fileparts(Settings.ImageNamesList{ind});
set(handles.FileText,'FontSize',6.0)
set(handles.FileText,'String',[name ext])

% Get params from GUI
color = GetPopupString(handles.ColorScheme);
val = get(handles.BlinkSpeed,'Value');
SpeedOptions = [0 1.5 .75 .25 handles.MaxSpeed];
speed = SpeedOptions(val);
val = get(handles.LineWidth,'Value');
WidthOptions = [0.01 1 3];
width = WidthOptions(val);

% Read Pattern and plot with overlay
axes(handles.Pattern)
if get(handles.Filter,'Value')
    ImageFilter = Settings.ImageFilter;
    if strcmp(Settings.ImageFilterType,'standard')
        I2=ReadEBSDImage(Settings.ImageNamesList{ind},ImageFilter);
    else
        I2=localthresh(Settings.ImageNamesList{ind});
    end
else
    I2=ReadEBSDImage(Settings.ImageNamesList{ind},[0 0 0 0]);
end
im = imagesc(I2); axis image; xlim([0 pixsize]); ylim([0 pixsize]); colormap('gray'); axis off;

if strcmp(GetPopupString(handles.SimType),'Dynamic')
    GenPat = genEBSDPatternHybrid_fromEMSoft(g,xstar,ystar,zstar,pixsize,mperpix,elevang,phase,Av,ind);
    cla(handles.DynamicPattern)
    h = imagesc(handles.DynamicPattern,GenPat); colormap(handles.DynamicPattern,gray);
    uistack(handles.DynamicPattern,'top')
    axis(handles.DynamicPattern,'image','off')
    if speed == handles.MaxSpeed
        set(h,'Visible','off')
    elseif speed > 0
        blinkline(h,speed)
    else
        blinkline(h);blinkline(h);
    end
else
    if isfield(Settings,'camphi1')
        paramspat{11} = Settings.camphi1;
        paramspat{12} = Settings.camPHI;
        paramspat{13} = Settings.camphi2;
    end
    genEBSDPatternHybridLineOverlay(g,paramspat,eye(3),Material.lattice,Material.a1,Material.b1,Material.c1,Material.axs,...
        'BlinkSpeed',speed,'Color',color,'MaxSpeed',handles.MaxSpeed,...
        'LineWidth',width);
    if strcmp(color,'holiday')
        colormap hot
        gui = findall(handles.PointSelectionGUI,'BackgroundColor',[0.94 0.94 0.94]);
        set(gui,'BackgroundColor','red')
        set(gui,'ForegroundColor','white','FontWeight','bold')
        set(handles.PointSelectionGUI,'Color','green')
    end
end

% Update RefrencePattern
axes(handles.ReferencePattern)
switch Settings.HROIMMethod
    case 'Simulated' % Kinematic Simulation
        RefIm = genEBSDPatternHybrid(g,paramspat,eye(3),Material.lattice,...
            Material.a1,Material.b1,Material.c1,Material.axs);
        if handles.Filter.Value && any(Settings.ImageFilter)
            if strcmp(Settings.ImageFilterType,'standard') 
            RefIm = custimfilt(RefIm,Settings.ImageFilter(1),...
                Settings.PixelSize,Settings.ImageFilter(3),...
                Settings.ImageFilter(4));
            else
               RefIm = localthresh(RefIm); 
            end
        end
        handles.refInd = 0;
    case 'Dynamic Simulated' % Dynamic Simulation
        if exist('GenPat','var')
            RefIm = GenPat;
        else
            RefIm = genEBSDPatternHybrid_fromEMSoft(g,xstar,ystar,...
                zstar,pixsize,mperpix,elevang,phase,Av,ind);
        end
        if handles.Filter.Value && any(Settings.ImageFilter)
            if strcmp(Settings.ImageFilterType,'standard')
                RefIm = custimfilt(RefIm,Settings.ImageFilter(1),...
                    Settings.PixelSize,Settings.ImageFilter(3),...
                    Settings.ImageFilter(4));
            else
                RefIm = localthresh(RefIm);
            end
        end
        handles.refInd = 0;
    case 'Real' % Real Refernce Grain
        refInd = Settings.RefImageInd;
        if ~refInd
            refInd = Settings.RefInd(ind);
        end
        if get(handles.Filter,'Value')
            ImageFilter = Settings.ImageFilter;
            if strcmp(Settings.ImageFilterType,'standard')
                RefIm=ReadEBSDImage(Settings.ImageNamesList{refInd},ImageFilter);
            else
                RefIm=localthresh(Settings.ImageNamesList{refInd});
            end
        else
            RefIm=ReadEBSDImage(Settings.ImageNamesList{refInd},[0 0 0 0]);
        end
        handles.refInd = refInd;
end
imagesc(RefIm);
axis image;
xlim([0 pixsize]);
ylim([0 pixsize]);
colormap('gray');
axis off;

plotPoints(handles)

function plotPoints(handles)
% handles.plotPoints = false;
% MapSelection_SelectionChangedFcn(handles.MapSelection,0,handles)
% handles.plotPoints = true;
axes(handles.Points)
cla
hold on;

% Plot selected image
[Y,X] = find(handles.indi == handles.ind);
plot(X,Y,'kd','MarkerFaceColor','k','MarkerEdgeColor','w')

if handles.refInd
    [Y,X] = find(handles.indi == handles.refInd);
    plot(X,Y,'ro','MarkerFaceColor','r','MarkerSize',4,'MarkerEdgeColor','w')
end

hold off;

uistack(handles.GrainMap, 'top')
uistack(handles.Points, 'top')

% --- Executes on selection change in BlinkSpeed.
function BlinkSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to BlinkSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BlinkSpeed contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BlinkSpeed
if handles.ind
    PlotPattern(handles)
end


% --- Executes during object creation, after setting all properties.
function BlinkSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BlinkSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NumFam.
function NumFam_Callback(hObject, eventdata, handles)
% hObject    handle to NumFam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NumFam contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NumFam
if handles.ind
    PlotPattern(handles)
end

% --- Executes during object creation, after setting all properties.
function NumFam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumFam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function LineWidth_Callback(hObject, eventdata, handles)
% hObject    handle to LineWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
if handles.ind
    PlotPattern(handles)
end

% --- Executes during object creation, after setting all properties.
function LineWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LineWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Filter.
function Filter_Callback(hObject, eventdata, handles)
% hObject    handle to Filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Filter
if handles.ind
    PlotPattern(handles)
end

% --- Executes on selection change in ColorScheme.
function ColorScheme_Callback(hObject, eventdata, handles)
% hObject    handle to ColorScheme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ColorScheme contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ColorScheme
if handles.ind
    PlotPattern(handles)
end

% --- Executes during object creation, after setting all properties.
function ColorScheme_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColorScheme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PlotGB.
function PlotGB_Callback(hObject, eventdata, handles)
% hObject    handle to PlotGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotGB
% MapSelection_SelectionChangedFcn(handles.MapSelection, eventdata, handles)
if hObject.Value
    handles.GrainMap.Children.Visible = 'On';
    uistack(handles.GrainMap, 'top')
else
    handles.GrainMap.Children.Visible = 'Off';
end

   

function string = GetPopupString(Popup)
List = get(Popup,'String');
Value = get(Popup,'Value');
string = List{Value};

function SetPopupValue(Popup,String)
String = num2str(String);    
List = get(Popup,'String');
IndList = 1:length(List);
Value = IndList(strcmp(List,String));
if isempty(Value); Value =1; end;
set(Popup, 'Value', Value);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over BlinkText.
function BlinkText_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to BlinkText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on PointSelectionGUI and none of its controls.
function PointSelectionGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to PointSelectionGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
% Close Figure with CTRL-L
if strcmp(eventdata.Key,'l') && ~isempty(eventdata.Modifier) && strcmp(eventdata.Modifier,'control')
    SaveClose_Callback(handles.SaveClose, eventdata, handles);
end


% --- Executes on selection change in SimType.
function SimType_Callback(hObject, eventdata, handles)
% hObject    handle to SimType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SimType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SimType
if handles.ind
    PlotPattern(handles)
end

% --- Executes during object creation, after setting all properties.
function SimType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IndexNumEdit_Callback(hObject, eventdata, handles)
% hObject    handle to IndexNumEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IndexNumEdit as text
%        str2double(get(hObject,'String')) returns contents of IndexNumEdit as a double


% keyboard
if ~all(isstrprop(hObject.String,'digit')) || isempty(hObject.String)
   beep
   hObject.String = num2str(handles.ind);
   return;
end
val = str2double(hObject.String);
if val <= 0
    beep
    val = 1;
elseif val > handles.Settings.ScanLength
    beep
    val = handles.Settings.ScanLength;
end
handles.ind = val;
PlotPattern(handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function IndexNumEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IndexNumEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

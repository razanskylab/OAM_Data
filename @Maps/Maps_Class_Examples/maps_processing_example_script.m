if isunix
  addpath(genpath('/home/hofmannu/Documents/hfoam'));
end

% Example Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clj

% proccessed data stored in:
if ispc
  fullPath = 'C:\Data\processed_2017_10_19 - Normal All\015_mouse1Radiated_dye_processed.mat';
elseif isunix
  fullPath = '/media/hofmannu/storage/lab_notes_sync/2017_11_13_UH_Segmentation skull brain/mouse1/015_mouse1Radiated_dye_processed.mat';
end

temp = load_smart(fullPath);
ExpData = temp.ExpData;
clear 'temp'

M = Maps(ExpData);
M.Norm();
M.P; % plot xy map

% Do Some Image Pre Processing -------------------------------------------------
M.Apply_CLAHE();
M.P; % plot top mip, new figure
title('CLAHE Image')
%
% M.Sharpen();
% M.P; % plot top mip, new figure
% title('Sharpened Image')

% Frangi Filter image ----------------------------------------------------------
M.frangiShowScales = true; % show individual frangi scales
M.Apply_Frangi(); % frangi filtered xy map stored as M.filt
M.signal = M.filt;

Binarize(M); % calculte binary image M.bin
M.P(M.bin); colorbar('off');

% Plot Depth Map
M.depthInfo = ExpData; % get's depth info as max from full 3d
M.depthColorMap = parula(255);

M.P(M.signal);
title('Signal Map (Frangi Filtered)')
M.Plot_Depth_Map();

% export related stuff
distFig('Pos','C','Screen','Left','Transpose',true);
M.Path.extention = '';
M.Path.nameBase  = 'test';

M.Path.folder    = 'S:\classTesting\'; % set new export path...

M.exportJpg = 1;
M.exportPdf = 0;
M.exportAllFigure = 1; % export all create figures, not just latest one!
M.Export_Figures();



imbinarize(M.xy,graythresh(M.xy));

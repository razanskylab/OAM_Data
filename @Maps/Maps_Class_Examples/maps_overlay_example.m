% Author: Johannes Rebling
% Date    23. Nov. 2017
% Version 0.1
clj
% proccessed data stored in:
if ispc
  fullPath = 'C:\Data\mouse_no_1_postprocessed.mat';
elseif isunix
  fullPath = '/media/hofmannu/storage/lab_notes_sync/2017_11_13_UH_Segmentation skull brain/mouse1/015_mouse1Radiated_dye_processed.mat';
end

% smart load (using caching) into temp varibale
Temp = load_smart(fullPath);
ExpDataUS = Temp.postprocessed.us.ExpData;
ExpDataOA = Temp.postprocessed.oa.ExpData;
inSkullMask = Temp.postprocessed.inSkullMask;
belowSkullMask = Temp.postprocessed.belowSkullMask;
clear 'temp'

Oa = Maps(ExpDataOA);
Oa.xy(~inSkullMask) = 0;
Oa.Norm();
Oa.P(); title('In Skull - Raw');
Oa.Apply_CLAHE();
Oa.Apply_CLAHE();
Oa.P(); title('In Skull - Double Enhanced');

% apply frangi
Oa.frangiShowScales = true; % show individual frangi scales
Oa.frangiScaleRange = [2,7];
Oa.frangiScaleRatio = 1; % if frangiScaleRatio = 1,display ind. frangi scales on background image
Oa.Apply_Frangi();
Oa.P(Oa.filt); title('In Skull - Frangi');

% Take frangi filtere image, use this for binarziation
Oa.signal = Oa.filt;
Oa.Norm();
Oa.maskFrontCMap = Colors.whiteToGreen; % custom made color map, see Colors class
Oa.maskBackCMap = 'gray';
Oa.Overlay_Mask(Oa.xy); % overlays Oa.xy over default background, i.e. Oa.filt

%
% % export related stuff
% distFig('Pos','C','Screen','Left','Transpose',true);
% M.Path.extention = '';
% M.Path.nameBase  = 'test';
%
% M.Path.folder    = 'S:\classTesting\'; % set new export path...
%
% M.exportJpg = 1;
% M.exportPdf = 0;
% M.exportAllFigure = 1; % export all create figures, not just latest one!
% M.Export_Figures();

% imbinarize(M.xy,graythresh(M.xy));
drawnow;
distFig('Pos','C','Screen','Left','Transpose',true);

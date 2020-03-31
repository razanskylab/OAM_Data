close all; clear;

load('C:\Data\2018_06_07 - Chen Data\sigMat_printedpaper3_test2-v2_Recon_superimpose_3D.mat')
M = Maps(Recon_3D);
M.verboseOutput = true;
M.Norm(); % normalize
M.xy = medfilt2(M.xy,[5 5]);
M.Interpolate(2); % interpolate by factor 2 for pretier images

f = figure();
subplot(2,2,1)
  M.P(); % plot xy MAP
  title('Interpolated raw image');

% Clahe options
M.claheDistr  = 'exponential'; % 'uniform' 'rayleigh' 'exponential' Desired histogram shape
M.claheNBins  = 256; % histogram bins used for contrast enhancing transformation
M.claheLim    = 0.04; % enhancement limit, [0, 1], higher limits result in more contrast
M.claheNTiles = [32 32]; % image divided into M x N tiles, 'NumTiles' = [M N]

% enhance contrast
M.Apply_CLAHE();
subplot(2,2,2)
  M.P(); % plot xy MAP
  title('Contrast enhanced raw image');

% frangi filter, but it's not working great with this image
M.frangiShowScales = true; % show individual frangi scales
M.maskAlpha = 0.75; % transparency for overlaying frangi scales
M.frangiStartScale = 4;
M.frangiStopScale = 20;
M.frangiNoScales = 5;
M.frangiBetaOne = 10;
M.frangiBetaTwo = 2;

M.Apply_Frangi();
figure(f);
subplot(2,2,3)
  M.P(M.filt);
  title('Frangi Filtered');

subplot(2,2,4)
  M.P(M.filtScales(:,:,end));
  title('Last Frangi Scale');

% File:     Apply_frangi.m
% Author:   Johannes Rebling
% Version:  2.1
%

function [] = Apply_Frangi(M)
  % FIXME: add description here!
  % FIXME: return binary mask as well here or create new function that takes
  % the overall or seperate filtered images and analyses them to create
  % binary mask
  % IDEA: segment seperate scales, then use && to create overall mask???

  t1 = tic;
  if M.verboseOutput
    fprintf('Frangi filtering...\n');
  else
    fprintf('Frangi filtering...');
  end

  % get and display info about user define scales ------------------------------
  % these will be integer values right now
  % FIXME scale range should be expressed in microns or mm instead of integers

  allScales = linspace(M.frangiStartScale, M.frangiStopScale, M.frangiNoScales);
  nScales = numel(allScales);

  % scale ranges are influenced by actual physical size of image
  % i.e. by the pixel/mm aka pixeldensity
  % calculate pixel density [defined as pixels/mm] and correct scale range using it!
  % we store the old frangi scale range as class property and use effective values here
  % otherwise we get changing frangi settings if we run it multiple times.

  % get step size (mm/pixel) for x and y, warn if there is a large step size differece
  pixelSize = M.dR;
  % Calculate pixel density [defined as pixels/m]
  pixelDensity = 1 / pixelSize*1e3;
  AllEffectiveScales = allScales.*pixelDensity*1e-5;

  % Normalize
  M.Norm();
  M.filt = M.xy;

  if M.verboseOutput
    fprintf('   Pixel density = %2.1f pixels/mm\n', pixelDensity/1000);
    fprintf('   Pixel size = %2.1f microm\n', pixelSize*1e3);
    fprintf('   Using %i scales (from %i to %i)\n', nScales,M.frangiStartScale,...
      M.frangiStopScale);
    fprintf('   Using %i effective scales (from %2.1f to %2.1f)\n',...
      nScales, AllEffectiveScales(1), AllEffectiveScales(end));
  end

  if M.verboseOutput
    % Pad Image to be filtered to avoid edge effects
    fprintf('   Add padding to image...\n');
  end
  padSizes = size(M.filt) * round(M.paddingFactor / 100);
  M.filt  = padarray(M.filt, padSizes, M.padVal);


  % Perform actual frangi filtering
  if M.verboseOutput
    jprintf('   Perform actual frangi filtering...');
  end
  options = struct('AllEffectiveScales', AllEffectiveScales,...
                   'FrangiBetaOne', M.frangiBetaOne,...
                   'FrangiBetaTwo', M.frangiBetaTwo,...
                   'verbose',false,...
                   'BlackWhite',M.frangiInvert,...
                   'pixelDensity', pixelDensity);
  [M.filt,M.filtScales] = FrangiFilter2D_fast(M.filt, options);

  % Remove padding
  if M.verboseOutput
    fprintf('   Remove padding...\n');
  end
  M.filt = M.filt((padSizes(1)+1):(end-padSizes(1)),(padSizes(2)+1):(end-padSizes(2)));
  M.filtScales = M.filtScales((padSizes(1)+1):(end-padSizes(1)),(padSizes(2)+1):(end-padSizes(2)),:);

  % show seperate frangi scales in their own figure if M.frangiShowScales
  if M.frangiShowScales
    M.Show_Frangi();
  end

  M.filt = normalize(M.filt);
  % normalize again to be safe
  if M.verboseOutput
    fprintf('Frangi filtering completed in %2.1f s.\n',toc(t1));
  else
    done(toc(t1));
  end

end

function [] = Show_Frangi(M)
  % handle figures
  fprintf('   Plotting frangi filtered images...\n');
  figure() % always create scales in seperate figure
  M.oldFigureHandles{end+1} = gcf;

  % get scale info
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

  % find number of scales for plotting
  [m,n] = find_subplot_dividers(nScales+1); % +1 to always show orig raw image

  % always plot raw image that was used for filtering
  subplot_tight(m,n,1);
    montage = imfuse(M.xy,M.filt,'montage');
    imshow(montage);
  title('Unfiltered vs filtered raw image');

  for iPlot = 1:nScales
    % fprintf(['    Plotting frangi scale ', num2str(iPlot) , '...\n']);
    filtImage = M.filtScales(:,:,iPlot);
    filtImage = normalize(filtImage);
    filtImage = adapthisteq(filtImage,'Distribution',M.claheDistr,'NBins',M.claheNBins,...
      'ClipLimit',M.claheLim,'NumTiles',M.claheNTiles);
    [~,montage] = im_overlay(M.xy,filtImage);
    subplot_tight(m,n,iPlot+1);
      imshow(montage);
      % don't create new figures for each scale, we have subplots for that
      % but we have to change the M.newFigPlotting settings as it's used in Overlay_Mask
      scaleFwhm = 2.3548 * AllEffectiveScales(iPlot) / (pixelDensity * 1e-6);
      title(sprintf('S: %i, FWHM: %2.0f \\mum',iPlot,scaleFwhm));
  end
  % for iPlot = 1:nScales
  %   % fprintf(['    Plotting frangi scale ', num2str(iPlot) , '...\n']);
  %   subplot(m,n,(2*iPlot-1)+2);
  %     imagescj(M.filtScales(:,:,iPlot),'hot');axis off;
  %   subplot(m,n,(2*iPlot)+2);
  %     % don't create new figures for each scale, we have subplots for that
  %     % but we have to change the M.newFigPlotting settings as it's used in Overlay_Mask
  %     oldSetting = M.newFigPlotting;
  %     M.newFigPlotting = 0;
  %     M.Overlay_Mask(M.filtScales(:,:,iPlot), M.xy);
  %     scaleFwhm = 2.3548 * AllEffectiveScales(iPlot) / (pixelDensity * 1e-6);
  %     title(sprintf('S: %i, FWHM: %2.0f \\mum',iPlot,scaleFwhm));
  %     M.newFigPlotting = oldSetting; % restore previous setting
  % end
end

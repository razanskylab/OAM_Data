function [cBar] = Overlay_Mask(M,front,back,transparency,alphaMask)
  % show a background image (typically M.signal) and overlay it with a second
  % image of the same size using a second colormap and an opacity argument
  % based on overlayPlot form k-Wave toolbox and the matlab file exchange
  % function showMaskAsOverlay, but both are not exactly what we need...
  % front - image to overlay
  % back - iamge to have as background
  % transparency - overall max transparency of the mask
  % alphaMask - multiply alpha mask by this mask

  % M.Handle_Figures();
  num_colors = size(M.maskFrontCMap,1);

  if nargin < 2
    back = M.signal;
    transparency = M.maskAlpha;
    alphaMask = [];
  elseif nargin < 3
    back = M.signal;
    front = M.xy;
    transparency = M.maskAlpha;
    alphaMask = [];
  elseif nargin < 4
    transparency = M.maskAlpha;
    alphaMask = [];
  elseif nargin < 5
    alphaMask = [];
  end

  % get background and foreground colormaps
  if ischar(M.maskBackCMap)
    eval(['M.maskBackCMap = ' M.maskBackCMap '(num_colors);']); % turn string to actual colormap matrix
  end
  if ischar(M.maskFrontCMap)
    eval(['M.maskFrontCMap = ' M.maskFrontCMap '(num_colors);']); % turn string to actual colormap matrix
  end
  % scale the background image from 0 to num_colors
  back = back - min(back(:));
  back = round(num_colors.*back./max(back(:)));

  % convert the background image to true color
  back = ind2rgb(back', M.maskBackCMap);

  im = imagesc(M.x,M.y,back);
  axis image;
  ax = gca;
  colormap(ax,'gray');
  c = colorbar();
  c.TickLength = 0;
  c.Ticks = [min(c.Ticks) max(c.Ticks)];
  % axis off;

  % keep orig range for correct colormap
  minFront = min(front(:));
  maxFront = max(front(:));

  % scale the background image from 0 to num_colors
  front = front - min(front(:));
  front = front./max(front(:));
  frontIm = round(num_colors.*front./max(front(:)));
  frontIm = ind2rgb(frontIm', M.maskFrontCMap);

  if ~isempty(alphaMask)
    alpha = alphaMask;
  else
    alpha = front; % alpha channel based on foreground intentsity!!!
  end
  alpha = alpha.*transparency;

  hold on;
  im = imagesc(M.x,M.y,frontIm);
  axis image;
  ax = gca;
  c = colorbar();
  c.TickLength = 0;
  c.Ticks = [min(c.Ticks) max(c.Ticks)];

  % axis off;
  set(im, 'AlphaData', alpha');
  ax = gca;
  colormap(ax,M.maskFrontCMap);
  c = colorbar;
  cBar = colorbar('Ticks', [min(c.Ticks) max(c.Ticks)],...
         'TickLabels',{sprintf('%2.2f',minFront),sprintf('%2.2f',maxFront)});
  axis xy;
  hold off;
end

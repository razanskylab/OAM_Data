function Binarize(M,mapToUse)
  % create deep copy of map, binarize this one, save bin image to origMap

  % Segment xy map into binary image
  if nargin == 2 && ismatrix(mapToUse) % use provided map to segment
    fprintf('[Maps.Binarize] Segmenting using provdide MAP...\n');
    M.bin = imbinarize(mapToUse,graythresh(mapToUse)-0.1);
  elseif isnumeric(M.binWhat) % segment based on existing data
    switch M.binWhat
      case 0 % use frangi filtered image
        fprintf('[Maps.Binarize] Segmenting using Frangi map (M.filt)...\n');
        M.bin = frangi_binarize_image(M); % fct. definition below!
      case 1 % use xy map image
        fprintf('[Maps.Binarize] Segmenting using xy map (M.xy)...\n');
        M.bin = imbinarize(M.xy,graythresh(M.xy)-0.1);
      case 2 % use signal map image
        fprintf('[Maps.Binarize] Segmenting using signal map (M.signal)...\n');
        M.bin = imbinarize(M.signal,graythresh(M.signal)-0.1);
      otherwise
        error('[Maps.Binarize] You did not specify a valid basis for binarization.');
    end
  else
    error('[Maps.Binarize] Need to know what to binarize!\n');
  end
end

% Frangi Binarization Function Definiton %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [binImage] = frangi_binarize_image(M)
    BinFrangi = Frangi_Filter(M); % create member of frangi class

    % perform frangi analysis for all steps
    BinFrangi.startScale = M.binFrangiStart;
    BinFrangi.stopScale = M.binFrangiStop;
    BinFrangi.nScales = M.binFrangiNoScales;

    % Create frangi filtered images
    BinFrangi.Apply();

    frangiHist = adapthisteq(BinFrangi.filt,'clipLimit',1-M.binFinalThreshold);
    frangiHist = normalize(frangiHist);
    if M.binMultiplyMap
      frangiHist = frangiHist.*adapthisteq(M.xy);
    end

    % Thresholding
    % the lower the threshold, the more will be considered as vessel
    frangiBin = frangiHist>M.binFinalThreshold;

    % Create overlay figure
    % f = figure;
    if M.verbosePlotting
      M.Handle_Figures;
      subplot(2,2,1);
        imagescs(BinFrangi.filt); title('BinFrangi.filt')
      subplot(2,2,2);
        imagescs(frangiHist); title('HistEq-Frangi Image')
      subplot(2,2,3);
        imagescs(frangiBin); title('Binarized')
      subplot(2,2,4);
        M.Overlay_Mask(frangiBin, adapthisteq(M.xy), 0.5);
        title(['Overlay - Threshold: ', num2str(M.binFinalThreshold)]);
    end

    % Convert to logical
    binImage = logical(frangiBin);

end

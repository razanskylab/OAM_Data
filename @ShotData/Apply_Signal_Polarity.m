% [out] = Apply_Signal_Polarity(FSP,In) @ FSP
%
% sigMat can be 2D or 3D but last dimension needs to be time/z-dimension
% signalPolarity = FSP.signalPolarity
% 0 = pos. and neg. signals, 1 = pos. only, -1 = neg. signals only, % 2 = hilbert
% parallelProcessing = FSP.runInParallel;
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [sigMat] = Apply_Signal_Polarity(SDO, sigMat)
  tic;

  if ~SDO.verboseOutput
    SDO.PrintF('Applying signal polarity...\n');
  elseif SDO.signalPolarity
    SDO.VPrintF('Changing signal polarity:\n');
  end

  % check that the selected polarity makes sense
  sigMinMax = minmax(sigMat);

  dataType = class(sigMat); % get data type to later restore it

  switch SDO.signalPolarity
    case 0
      SDO.VPrintF('   Using positive and negative US signals!\n')
    case 1

      if sigMinMax(1) <= 0
        short_warn('No signals > 0, not possible to use only positive values!');
        return;
      end

      SDO.VPrintF('   Using only positive signals!\n')
      sigMat(sigMat < 0) = 0; % take pos only values
    case -1

      if sigMinMax(0) >= 0
        short_warn('No signals < 0, not possible to use only negative values!');
        return;
      end

      SDO.VPrintF('   Using only negative signals!\n')
      sigMat(sigMat > 0) = 0; % take neg only values
      sigMat = -sigMat; % make all positive for plotting
    case 2
      SDO.VPrintF('   Calulating signal envelope...');
      sigMat = abs(hilbert(single(sigMat)));
      % NOTE conversion to single above improves speed, as sigMat is otherwise
      % converted to double
      % sigMat = mchilbert_mex(single(sigMat));
      % NOTE mchilbert_mex(single(sigMat)) does the same as abs(hilbert(single(sigMat)));
      % using a mex file, but it's not faster!
      SDO.VPrintF('done (%3.2f s).\n', toc());
    case 22
      % does the same as case 2 but requires minimal RAM
      % however this is ~10 times slower!
      SDO.VPrintF('   Calulating signal envelope (slow for-loop)...');

      for iShot = 1:SDO.nShots
        sigMat(:, iShot) = envelope(single(sigMat(:, iShot)));
      end

      SDO.VPrintF('done (%3.2f s).\n', toc());
    case 3
      SDO.VPrintF('   Using absolute values of signals.\n')
      sigMat = abs(sigMat); % take absolute values
    otherwise
      error('   FSP.signalPolarity must be -1, 0, 1, 2, 3 or 42!\n')
  end

  sigMat = cast(sigMat, dataType); % restore data type to what it was before

end

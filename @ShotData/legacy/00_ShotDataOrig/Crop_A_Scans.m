% [out] = Crop_A_Scans(SDO) @ SDO
% crop shots/a-scans as specified by range
% keep Range needs to be expressed in absolute values, check zCrop first if you
% are not sure!
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Crop_A_Scans(SDO,keepRange)
  if min(keepRange) < 1
    error('min(keepRange) has to be >= 1!');
  end

  if min(keepRange) < SDO.zCrop(1)
    error('min(keepRange) can''t be less than zCrop(1)!');
  end

  if max(keepRange) > SDO.zCrop(2)
    error('max(keepRange) can''t be bigger than zCrop(2)!');
  end
  tic();

  preSize = SDO.totalByteSize;
  startIdx = keepRange(1)-SDO.zCrop(1)+1;
  endIdx = startIdx + keepRange(end)-keepRange(1);

  if ~isempty(SDO.raw)
    SDO.raw = SDO.raw(startIdx:endIdx,:);
  end

  postSize = SDO.totalByteSize;
  perRemoved =  (1-postSize/preSize)*100;
  bytesRemoved = preSize - postSize;

  % update class properties to reflect that data was cropped
  SDO.zCrop = [keepRange(1) keepRange(end)];
  SDO.isCropped = true;

  % inform user how much we removed
  SDO.PrintF('Removed %2.0f%% (%sB) in %2.2fs.\n',...
    perRemoved, num_to_SI_string(bytesRemoved),toc());
end

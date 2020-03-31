% [out] = Remove_A_Scans(SDO) @ SDO
% remove those shots/a-scans specified in keepIdx (1d logical array)
% different from cropping, as cropping works with a range!
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Remove_A_Scans(SDO,keepIdx)
  if ~islogical(keepIdx)
    error('keepIdx needs to be logical!');
  end
  if numel(keepIdx) ~= SDO.nShots
    SDO.PrintF('numel(keepIdx)=%i nShots=%i\n',numel(keepIdx),SDO.nShots);
    error('Size of keepIdx not equal to number of shots!');
  end

  if ~isempty(SDO.raw)
    SDO.raw = SDO.raw(:,keepIdx);
  end

end

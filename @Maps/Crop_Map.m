function Crop_Map(M,xRange,yRange)
  % crop xy map, as well as all other maps that exist and the x and y vectors
  M.xy = M.xy(yRange,xRange);
  M.x = M.x(xRange);
  M.y = M.y(yRange);
  if ~isempty(M.filt)
    M.filt = M.filt(yRange,xRange);
  end
  if ~isempty(M.bin)
    M.bin = M.bin(yRange,xRange);
  end
  if ~isempty(M.depthInfo)
    M.depthInfo = M.depthInfo(yRange,xRange);
  end
  if ~isempty(M.rawDepth)
    M.rawDepth = M.rawDepth(yRange,xRange);
  end
  if ~isempty(M.filtDepth)
    M.filtDepth = M.filtDepth(yRange,xRange);
  end

end

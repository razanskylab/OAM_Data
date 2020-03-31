% [out] = Function_Name(SDO,In) @ SDO
% text here
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [out] = Function_Name(SDO,In)
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs

  dataType = class(sigMat); % get data type to later restore it

  sigMat = cast(sigMat,dataType); % restore data type to what it was before

end

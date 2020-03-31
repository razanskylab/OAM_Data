function Plot_Aova_Result(Maps)
  Maps.Handle_Figures(); % make new figure or use old figure handle, see fct def for details

  branchColor = Colors.DarkPurple;
  branchMarkerSize = 40;
  centerColor = Colors.DarkOrange;

  % imagescj(Maps.xy); colorbar('off'); axis('off');
  imagescj(normalize(adapthisteq(Maps.xy,'ClipLimit',0.02)),'gray'); colorbar('off'); axis('off');
  hold on;
  title('AOVA Results');
  if ~isempty(Maps.VesselData.branchCenters)
      scatter(Maps.VesselData.branchCenters(:,1),Maps.VesselData.branchCenters(:,2),...
        branchMarkerSize,'filled','MarkerFaceColor',branchColor);
  end


  plot_vessel_centerlines(Maps.VesselData.vessel_list,centerColor,2);
  plot_vessel_edges(Maps.VesselData.vessel_list,centerColor,1);

  legend({'Branch Points','Centerlines','Edges'});

end

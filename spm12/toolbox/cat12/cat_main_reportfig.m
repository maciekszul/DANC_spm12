function cat_main_reportfig(Ym,Yp0,Yl1,Psurf,job,qa,res,str)
% ______________________________________________________________________
% 
% Display CAT report in the SPM grafics window and save a PDF and JPG
% file in the report directory.
%
%   cat_main_reportfig(Ym,Yp0,Psurf,job,res,str);
%
%   Ym      .. intensity normalized image
%   Yp0     .. segmentation label map
%   Psurf   .. central surface file
%   job     .. SPM/CAT parameter structure
%   res     .. SPM result structure
%   str     .. Parameter strings (see cat_main_reportstr)
%   Yl1     .. Label map for ventricle and WMHs
%   qa      .. WMH handling
%
%   See also cat_main_reportstr and cat_main_reportcmd.
% ______________________________________________________________________
%
%   Robert Dahnke (robert.dahnke@uni-jena.de)
%   Structural Brain Mapping Group (http://dbm.neuro.uni-jena.de/)
%   Department of Neurology
%   University Jena
% ______________________________________________________________________
% $Id: cat_main_reportfig.m 1430 2019-02-19 16:01:28Z gaser $
  
  %#ok<*TRYNC>
  
 % warning off; %#ok<WNOFF> % there is a div by 0 warning in spm_orthviews in linux

  dbs = dbstatus; debug = 0; for dbsi=1:numel(dbs), if strcmp(dbs(dbsi).name,mfilename); debug = 1; break; end; end
 
  VT  = res.image(1); 
  VT0 = res.image0(1);
  [pth,nam] = spm_fileparts(VT0.fname); 
   
  % definition of subfolders
  if job.extopts.subfolders
    reportfolder  = 'report';
  else
    reportfolder  = '';
  end
  
  nprog = ( isfield(job,'printPID') && job.printPID ) || ... PID field
          ( isempty(findobj('type','Figure','Tag','CAT') ) && ... no menus
            isempty(findobj('type','Figure','Tag','Menu') ) );
  fg  = spm_figure('FindWin','Graphics'); 
  set(0,'CurrentFigure',fg)
  if isempty(fg)
    if nprog
      fg = spm_figure('Create','Graphics','visible','off'); 
    else
      fg = spm_figure('Create','Graphics','visible','on'); 
    end;
  else
    if nprog, set(fg,'visible','off'); end
  end
  set(fg,'windowstyle','normal'); 
  spm_figure('Clear',fg); 
  switch computer
    case {'PCWIN','PCWIN64'}, fontsize = 8;
    case {'GLNXA','GLNXA64'}, fontsize = 8;
    case {'MACI','MACI64'},   fontsize = 9.5;
    otherwise,                fontsize = 9.5;
  end
  ax=axes('Position',[0.01 0.75 0.98 0.24],'Visible','off','Parent',fg);

  text(0,0.99,  ['Segmentation: ' spm_str_manip(res.image0(1).fname,'k60d') '       '],...
    'FontSize',fontsize+1,'FontWeight','Bold','Interpreter','none','Parent',ax);

  cm = job.extopts.colormap; 

  % check colormap name
  switch lower(cm)
    case {'jet','hsv','hot','cool','spring','summer','autumn','winter',...
        'gray','bone','copper','pink','bcgwhw','bcgwhn'}
    otherwise
      cat_io_cprintf(job.color.warning,'WARNING:Unknown Colormap - use default.\n'); 
      cm = 'gray';
  end

  % SPM_orthviews work with 60 values. 
  % For the surface we use a larger colormap.
  surfcolors = 128; 
  switch lower(cm)
    case {'bcgwhw','bcgwhn'} 
      % CAT colormap with larger range colorrange from 0 (BG) to 1 (WM) to 2 (HD).  
      ytick        = [1,5:5:60];
      yticklabel   = {' BG',' ',' CSF',' CGM',' GM',' GWM',' WM',' ',' ',' ',' ',' ',' BV / HD '};
      yticklabelo  = {' BG',' ','    ','    ','   ','     ',' avg WM  ',' ',' ',' ',' ',' ',' BV / HD '};
      yticklabeli  = {' BG',' ','    ','    ','   ','  ','  ',' ',' ',' ',' ',' ',' BV / HD '};
      cmap         = [cat_io_colormaps([cm 'ov'],60);flipud(cat_io_colormaps([cm 'ov'],60));jet(surfcolors)]; 
      cmmax        = 2;
    case {'jet','hsv','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink'}
      % default colormaps 
      ytick        = [1 20 40 60]; 
      yticklabel   = {' BG',' CSF',' GM',' WM'};
      yticklabelo  = {' BG','    ','   ',' WM'};
      yticklabeli  = {' BG','    ','   ','   '};
      cmap         = [eval(sprintf('%s(60)',cm));flipud(eval(sprintf('%s(60)',cm)));jet(surfcolors)]; 
      cmmax        = 1;
  end
  
  % For the segmentation map an overlay color map is used that is
  % independent of the first colormap.
  ytickp0      = [    1,   13,   18,    26,   35,   44,     52,    56,      60];
  if job.extopts.expertgui>1
    yticklabelp0 = {' BG',' HD',' BG',' CSF',' GM',' WM',' WMHs',' Ventricle',' GM > CSF'};
  else
    yticklabelp0 = {' BG',' HD',' BG',' CSF',' GM',' WM',' WMHs',' ',' GM>CSF'};
  end
  if job.extopts.WMHC<2 
    if qa.subjectmeasures.vol_rel_CGW(4)>0.03 || ...
       qa.subjectmeasures.vol_rel_CGW(4)/qa.subjectmeasures.vol_rel_CGW(3)>0.05
      yticklabelp0{end-2} = ' \color[rgb]{1,0,1}uncorrected WMHs = GM!';
    else
      yticklabelp0{end-2} = ' no/small WMHs';
    end
  elseif job.extopts.WMHC==2 
    yticklabelp0{end-2} = ' \color[rgb]{1,0,1}WMHs > WM';
  end

  colormap(cmap);
  spm_orthviews('Redraw');

  warning('OFF','MATLAB:tex')
  htext = zeros(5,2,2);
  for i=1:size(str{1},2)   % main parameter
    htext(1,i,1) = text(0.01,0.98-(0.055*i), str{1}(i).name  ,'FontSize',fontsize, 'Interpreter','none','Parent',ax);
    htext(1,i,2) = text(0.51,0.98-(0.055*i), str{1}(i).value ,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
  end
  for i=1:size(str{2},2)  % qa-measurements
    htext(2,i,1) = text(0.01,0.45-(0.055*i), str{2}(i).name  ,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
    htext(2,i,2) = text(0.25,0.45-(0.055*i), str{2}(i).value ,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
  end
  % qa-scala
  %htext(5,1,1) = text(0.01,0.45-(0.055*(i+2)),str4(1).name,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
  for i=1:size(str{3},2)  % subject-measurements
    htext(3,i,1) = text(0.51,0.45-(0.055*i), str{3}(i).name  ,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
    htext(3,i,2) = text(0.70,0.45-(0.055*i), str{3}(i).value ,'FontSize',fontsize, 'Interpreter','tex','Parent',ax);
  end

  % position values of the orthview/surface subfigures
  pos = [0.01 0.38 0.48 0.36; 0.51 0.38 0.48 0.36; ...
         0.01 0.01 0.48 0.36; 0.51 0.01 0.48 0.36];
  spm_orthviews('Reset');


  % BB box is not optimal for all images
  disptype = 'affine'; 
  warning('OFF','MATLAB:handle_graphics:exceptions:SceneNode')
  switch disptype
    case 'affine'
      dispmat = res.Affine; 
      warning('OFF','MATLAB:tex')
      spm_orthviews('BB', job.extopts.bb*0.95 );
    case 'ridid'
      % this does not work so good... AC has a little offset ...
      aff = spm_imatrix(res.Affine);  scale = aff(7:9); 
      spm_orthviews('BB', job.extopts.bb ./ mean(scale));
      dispmat = R; 
  end


  %  Yo - original image in original space
  %  ----------------------------------------------------------------------
  %  Using of SPM peak values didn't work in some cases (5-10%), so we have 
  %  to load the image and estimate the WM intensity. 
  try Yo  = single(VT0.private.dat(:,:,:)); end
  if isfield(res,'spmpp')
    VT0x = res.image0(1); 
  else
    VT0x = VT0;
  end
  
  if exist('Yo','var')
    
    if any(size(Yo)~=size(Yp0))
      try Yo = single(VT.private.dat(:,:,:)); end
      if isfield(res,'spmpp')
        VT0x = res.image(1); 
      else
        VT0x = VT;
      end
    end
    
    % remove outlier to make it orthviews easier
    Yo = cat_stat_histth(Yo,99.99); 
   
    if job.inv_weighting
      WMth = cat_stat_nanmedian(Yo(Yp0(:)>2.5 & Yp0(:)<3.5))/2*3;
      T1txt = '*.nii (Original PD/T2)'; 
    else
      WMth = cat_stat_nanmedian(Yo(Yp0(:)>2.8 & Yp0(:)<3.2)); clear Yo; 
      T1txt = '*.nii (Original T1)'; 
    end
    if ~debug, clear Yo; end

    VT0x.mat = dispmat * VT0x.mat; 
    hho = spm_orthviews('Image',VT0x,pos(1,:));
    spm_orthviews('Caption',hho,{T1txt},'FontSize',fontsize,'FontWeight','Bold');
    spm_orthviews('window',hho,[0 WMth*cmmax]); caxis([0,2]);
    cc{1} = axes('Position',[pos(1,1) + 0.26 0.37 0.02 0.15],'Parent',fg);     
    try image(cc{1},(60:-1:1)'); end

    if job.inv_weighting
      set(cc{1},'YTick',ytick,'YTickLabel',fliplr(yticklabeli),'XTickLabel','','XTick',[],'TickLength',[0 0],...
        'FontSize',fontsize,'FontWeight','Bold','YAxisLocation','right');
    else  
      set(cc{1},'YTick',ytick,'YTickLabel',fliplr(yticklabelo),'XTickLabel','','XTick',[],'TickLength',[0 0],...
        'FontSize',fontsize,'FontWeight','Bold','YAxisLocation','right');
    end
  else
    cat_io_cprintf('warn','WARNING: Can''t display original file "%s"!\n',VT.fname); 
  end


  %  Ym - normalized image in original space
  %  ----------------------------------------------------------------------
  if ~isfield(res,'spmpp') 
    %%
    Vm        = res.image(1); 
    Vm.fname  = ''; 
    Vm.dt     = [spm_type('FLOAT32') spm_platform('bigend')];
    Vm.dat(:,:,:) = single(Ym);                                % intensity normalized 
    %Vm.dat(:,:,:) = single(Ym .* min(1,3/12 + (Yp0>1/6)));      % intensity normalized with brainmask (incorrect axis label)
    Vm.pinfo  = repmat([1;0],1,size(Ym,3));
    Vm.mat    = dispmat * Vm.mat; 
    hhm = spm_orthviews('Image',Vm,pos(2,:));
    spm_orthviews('Caption',hhm,{'m*.nii (Int. Norm.)'},'FontSize',fontsize,'FontWeight','Bold');
    spm_orthviews('window',hhm,[0 cmmax]); caxis([0,2]);
    cc{2} = axes('Position',[pos(2,1) + 0.26 0.37 0.02 0.15],'Parent',fg);
    try image(cc{2},(60:-1:1)'); end 
    set(cc{2},'YTick',ytick,'YTickLabel',fliplr(yticklabel),'XTickLabel','','XTick',[],'TickLength',[0 0],...
      'FontSize',fontsize,'FontWeight','Bold','YAxisLocation','right');
  end
 
  
  
  %  Yp0 - segmentation in original space
  %  ----------------------------------------------------------------------
  %  Use different kind of overlays to visualize the segmentation: 
  %   0 - old default 
  %       (only brain tissue with the standard colormap)
  %   1 - default + head 
  %       (bad handling of PVE head values)
  %
  %   2 - color overlay for head and brain (DEFAULT)
  %       (good for skull stripping but worste representation of brain tissues) 
  %   3 - color overlay for head and brain (inverse head) 
  %       (good for skull stripping but worste representation of brain tissues) 
  %
  %   4 - black background + gray head + cat brain colors
  %       (miss some details in CSF tissues)
  %   5 - white background + gray head + cat brain colors (inverse head) 
  %       (more similar to other backgrounds)
  % 
  %  Currently, no overlay and overlay 2 are the best supported options. 
  %  Other options are only for internal test or development and can maybe
  %  removed in future (RD 20190110).
  
  useoverlay = 2; %(job.extopts.expertgui>1) * 2;
  VO         = res.image(1); 
  VO.fname   = ''; 
  VO.dt      = [spm_type('FLOAT32') spm_platform('bigend')];
  
  % create main brackground image
  if useoverlay == 3
    % show brain and head tissues
    VO.dat(:,:,:) = single(Yp0/3) + ...
      max(0,min(2, 2 - Ym )) .* (Yp0<0.5 & Ym<1/2) + ...
      max(0,min(2, 2 - Ym )) .* (Yp0<0.5 & Ym>1/2);
  elseif useoverlay
    % show brain and head tissues
    VO.dat(:,:,:) = single(Yp0/3) + ...
      min(0.4,     Ym/2 ) .* (Yp0<0.5 & Ym<1/2) + ...
      min(2.0, 2 + Ym/2 ) .* (Yp0<0.5 & Ym>1/2);
  else
    % old default: show only brain tissues
    VO.dat(:,:,:) = single(Yp0/3);
  end
  
  
  VO.pinfo  = repmat([1;0],1,size(Yp0,3));
  VO.mat    = dispmat * VO.mat; 
  if exist('hhp0','var')
    spm_orthviews('Delete', hhp0); %#ok<NODEF>
    clear hhp0;
  end 
  hhp0    = spm_orthviews('Image',VO,pos(3,:));
  spm_orthviews('window',hhp0,[0 1.3]);

  LAB = job.extopts.LAB;
  NS  = @(Ys,s) Ys==s | Ys==s+1;
  if useoverlay>1
    spm_orthviews('window',hhp0,[0 2]);
    V2 = VO;
    switch useoverlay
      case 22 % classic red mask
        V2.dat(:,:,:) = min(59,min(1,Yp0/3) + 60*(smooth3((abs(Yp0 - Ym*3)>0.6).*cat_vol_morph(abs(Yp0 - Ym*3)>0.8,'d',2).*(Yp0>0.5))>0.5)); 
        spm_orthviews('addtruecolourimage',hhp0,V2,...
          [0.05 0.4 1; gray(58); 0.8 0.2 0.2],0.5,3,0)
      case 2 % red mask high contrast (default)
        
        % basic head/brain tissue
        if 0 % pink head 
          BCGWH = pink(15); fx = 4; 
        elseif 0 % green head 
          BCGWH = [0 0.1 0.05; 0.05 0.2 0.1; 0.1 0.3 0.2; 0.15 0.4 0.3; summer(11)]; fx = 3; 
        else % blue head 
          BCGWH = [0 0.05 0.1; 0.05 0.1 0.20; cat_io_colormaps('blue',13)];fx = 3;
        end
        V2.dat(:,:,:) = min(0.49,Ym/fx).*(Yp0<0.5) + (Yp0/3+0.5).*(Yp0>0.5); 
        
        % meninges/blood vessels: GM > CSF
        Ychange = 60*(smooth3( ...
          (abs(Yp0 - Ym*3)>0.4) .* (Yp0<1.25) .* ~NS(Yl1,LAB.VT) .* ...
          cat_vol_morph(abs(Yp0 - Ym*3)>0.5,'d',2) .* ...
          (Yp0>0.5))>0.5);
        %V2.dat(NS(Yl1,LAB.BV))     = 57/30; % BV???
        V2.dat(Ychange & Ym<1.33/3) = 58/30;
        V2.dat(Ychange & Ym>1.33/3) = 59/30;
        V2.dat(Ychange & Ym>1.66/3) = 60/30; 
        
        % WMHs
        if job.extopts.WMHC > 1 || (qa.subjectmeasures.vol_rel_CGW(4)>0.03 || ...
          qa.subjectmeasures.vol_rel_CGW(4)/qa.subjectmeasures.vol_rel_CGW(3)>0.05)
          V2.dat(NS(Yl1,LAB.HI)) = 52/30;
        end
        
        % ventricles
        if job.extopts.expertgui > 1
          V2.dat(NS(Yl1,LAB.VT) & Yp0<1.5) = 55/30;
          V2.dat(NS(Yl1,LAB.VT) & Yp0>1.5) = 56/30;
          V2.dat(NS(Yl1,LAB.VT) & Yp0>2.5) = 57/30;
          vent3 = repmat([0.3 0.3 0.5],3,1); 
          vent3 = max(0,min(1,vent3 .* repmat([1;2;3],1,3))); 
        else
          vent3 = repmat([0.8 0.0 0.0],3,1); 
        end
        
        % colormap of WMHs
        g29 = gray(39); g29(1:7,:) = []; g29(end-3:end,:) = [];
        if job.extopts.WMHC < 2
          if qa.subjectmeasures.vol_rel_CGW(4)>0.03 || ...
            qa.subjectmeasures.vol_rel_CGW(4)/qa.subjectmeasures.vol_rel_CGW(3)>0.05
            wmhc9 = cat_io_colormaps('magenta',9);
          else
            wmhc9 = gray(20); wmhc9(1:10,:) = []; wmhc9(end,:) = []; 
            wmhc9 = flipud(wmhc9);
          end
        else
          wmhc9 = cat_io_colormaps('orange',9);
        end
        
        % colormap of blood vessels
        bv3 = [0.4 0.2 0.2; 0.6 0.2 0.2; 1 0 0];
        
        % mapping
        spm_orthviews('addtruecolourimage',hhp0,V2,...
          [BCGWH; g29; wmhc9; vent3; bv3],1,2,0); % Change

      case 3 % red mask
        Ychange = 60*(smooth3((abs(Yp0 - Ym*3)>0.6).*cat_vol_morph(abs(Yp0 - Ym*3)>0.8,'d',2) .* (Yp0>0.5))>0.5);
        BCGWH = pink(15); BCGWH = min(1,BCGWH + [zeros(13,3);repmat((1:2)'/2,1,3)]); 
        V2.dat(:,:,:) = min(0.5,Ym/3).*(Yp0<0.5) + (Yp0/4*1.4+0.5).*(Yp0>0.5) + Ychange; %V2.dat(Yp0<0.5 & Yp0>2.5) = nan; %V2.dat = 3*(V2.dat>0.5)
        spm_orthviews('addtruecolourimage',hhp0,V2,...
          [flipud(BCGWH);gray(44);1 0 0],1,2,0);
      case 4 % gray - color
        BCGWH = cat_io_colormaps('BCGWHwov',60); BCGWH(46:end,:) = []; 
        V2.dat(:,:,:) = min(0.5,Ym/3).*(Yp0<0.5) + (Yp0/4*1.4+0.5).*(Yp0>0.5); %V2.dat(Yp0<0.5 & Yp0>2.5) = nan; %V2.dat = 3*(V2.dat>0.5)
        spm_orthviews('addtruecolourimage',hhp0,V2,...
          [gray(16);BCGWH],1,2,0);
      case 5 % gray - color
        BCGWH = cat_io_colormaps('BCGWHnov',60); BCGWH(46:end,:) = []; 
        V2.dat(:,:,:) = min(0.5,Ym/3).*(Yp0<0.5) + (Yp0/4*1.4+0.5).*(Yp0>0.5); %V2.dat(Yp0<0.5 & Yp0>2.5) = nan; %V2.dat = 3*(V2.dat>0.5)
        spm_orthviews('addtruecolourimage',hhp0,V2,...
          [flipud(gray(16));BCGWH],1,2,0);
    end
    spm_orthviews('redraw');
  else
    spm_orthviews('window',hhp0,[0 cmmax]);
  end
  
  %% legend
  spm_orthviews('Reposition',[0 0 0]); 
  spm_orthviews('Caption',hhp0,'p0*.nii (Segmentation)','FontSize',fontsize,'FontWeight','Bold');
  spm_orthviews('window',hhp0,[0 cmmax]); caxis([0,2]);
  global st;
  if useoverlay>1
  % make SPM colorbar invisible (cannot delete it because SPM orthviews need it later)  
    %st.vols{3}.blobs{1}.cbar.Visible    = 'off';
    warning('OFF','MATLAB:warn_r14_stucture_assignment');
    st.vols{3}.blobs{1}.cbar.YTick       = ytickp0/30;
    st.vols{3}.blobs{1}.cbar.XTick       = [];
    st.vols{3}.blobs{1}.cbar.YTickLabel  = yticklabelp0;
    st.vols{3}.blobs{1}.cbar.XTickLabel  = {};
    st.vols{3}.blobs{1}.cbar.YAxisLocation = 'right';
    st.vols{3}.blobs{1}.cbar.Position = [pos(3,1) + 0.26 0.02 0.02 0.15]; 
    st.vols{3}.blobs{1} = rmfield(st.vols{3}.blobs{1},'cbar'); % remove handle to avoid position updates
  else
    cc{3} = axes('Position',[pos(3,1) + 0.26 0.02 0.02 0.15],'Parent',fg);
    try image(cc{3},(60:-1:1)'); end
    set(cc{3},'YTick',ytick,'YTickLabel',fliplr(yticklabel),'XTickLabel','','XTick',[],'TickLength',[0 0],...
      'FontSize',fontsize,'FontWeight','Bold','YAxisLocation','right');
  end
  if ~debug, clear Yp0; end
  %spm_orthviews('redraw');
  
  
  %% TPM overlay with brain/head and head/background surfaces
  warning('OFF','MATLAB:subscripting:noSubscriptsSpecified')
  showTPMsurf = 1; % ... also in default mode 
  if job.extopts.expertgui>0 - showTPMsurf
    %Phull = {fullfile(spm('dir'),'toolbox','cat12','templates_surfaces','bh.hull.cat.gii')};
    Phull = {cat_surf_create_TPM_hull_surface(res.tpm)};
    for id=1
      spm_orthviews('AddContext',id); % need the context menu for mesh handling

      spm_ov_mesh('display',id,Phull); 

      % apply affine scaling for gifti objects
      for ix=1:numel(Phull) 
        % load mesh
        spm_ov_mesh('display',id,Phull(ix)); 

        % apply affine scaling for gifti objects
        V = (dispmat * inv(res.Affine) * ([st.vols{id}.mesh.meshes(ix).vertices,...
             ones(size(st.vols{id}.mesh.meshes(ix).vertices,1),1)])' )';
        V(:,4) = [];
        M0 = st.vols{id}.mesh.meshes(1:ix-1);
        M1 = st.vols{id}.mesh.meshes(ix);
        M1 = subsasgn(M1,struct('subs','vertices','type','.'),single(V));
        st.vols{id}.mesh.meshes = [M0,M1];
      end

      %% change line style
      hM = findobj(st.vols{id}.ax{1}.cm,'Label','Mesh');
      UD = get(hM,'UserData');
      UD.width = 0.75; 
      UD.style = repmat({'b--'},1,numel(Phull));
      set(hM,'UserData',UD);
      spm_ov_mesh('redraw',id);
      spm_orthviews('redraw',id);

      %% TPM legend
      try % some error with text in MATLAB 2015b - ccl was no double?
        ccl{1} = axes('Position',[pos(1,1:2) 0 0] + [0.33 -0.005 0.02 0.02],'Parent',fg);
        cclp = plot(ccl{1},([0 0.4;0.6 1])',[0 0; 0 0],'b-'); text(double(ccl{1}),1.2,0,'TPM fit');
        set( cclp,'LineWidth',0.75); axis(ccl{1},'off')
      end
    end
  end
  
  %%
  if job.extopts.expertgui && exist('Psurf','var') && ~isempty(Psurf)
    % prepare brainmask as mesh
    %brainmesh = gifti( isosurface(Yp0,0.5) );
    %vmat  = VO.mat(1:3,:)*[0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
    %save( gifti(brainmesh) , []);
   
    %% add contex menu for principle test
    if job.extopts.expertgui>1
      ids = 1:3; 
    else
      ids = 3; %find(cellfun('isempty',st.vols)==0,1,'last');
    end
    
    for id=ids
      spm_orthviews('AddContext',id); % need the context menu for mesh handling

      for ix=1:numel(Psurf) 
        % load mesh
        spm_ov_mesh('display',id,Psurf(ix).Pcentral); 

        % apply affine scaling for gifti objects
        V = (dispmat * ([st.vols{id}.mesh.meshes(end).vertices,...
             ones(size(st.vols{id}.mesh.meshes(end).vertices,1),1)])' )';
        V(:,4) = [];
        M0 = st.vols{id}.mesh.meshes(1:end-1);
        M1 = st.vols{id}.mesh.meshes(end);
        M1 = subsasgn(M1,struct('subs','vertices','type','.'),single(V));
        st.vols{id}.mesh.meshes = [M0,M1];
      end

      %% change line style
      hM = findobj(st.vols{id}.ax{1}.cm,'Label','Mesh');
      UD = get(hM,'UserData');
      UD.width = [repmat(0.75,1,numel(UD.width) - numel(Psurf))  repmat(0.5,1,numel(Psurf))]; 
      UD.style = [repmat({'b--'},1,numel(UD.width) - numel(Psurf)) repmat({'k-'},1,numel(Psurf))];
      set(hM,'UserData',UD);
      spm_ov_mesh('redraw',id);
      
      %% TPM legend
      try
        ccl2{id} = axes('Position',[pos(id,1:2) 0 0] + [0.33 -0.015+0.02*(id>2) 0.02 0.02],'Parent',fg);
        plot(ccl2{id},[0 1],[0 0],'k-'); text(double(ccl2{id}),1.2,0,'CS'); axis(ccl2{id},'off')
      end
    end
    

    
    % remove menu
    %if ~debug, spm_orthviews('RemoveContext',id); end 
  end
  
  
  
  
  
  
  
%%
  imat = spm_imatrix(res.Affine); Rigid = spm_matrix([imat(1:6) 1 1 1 0 0 0]); clear imat;
  % surface
  if job.extopts.print>1
    if exist('Psurf','var') && ~isempty(Psurf)
      try
        spm_figure('Focus','Graphics'); 
        hCS = subplot('Position',[0.50 0.05 0.55 0.30],'visible','off'); 
        hSD = cat_surf_display(struct('data',Psurf(1).Pthick,'readsurf',0,'expert',2,...
          'multisurf',job.output.surface,'view','s','menu',0,...
          'parent',hCS,'verb',0,'caxis',[0 6],'imgprint',struct('do',0)));
       
        for ppi = 1:numel(hSD{1}.patch)
          V = (Rigid * ([hSD{1}.patch(ppi).Vertices, ones(size(hSD{1}.patch(ppi).Vertices,1),1)])' )'; 
          V(:,4) = []; hSD{1}.patch(ppi).Vertices = V;
        end
        
        colormap(cmap);  set(hSD{1}.colourbar,'visible','off'); 
        cc{4} = axes('Position',[0.63 0.02 0.3 0.01],'Parent',fg); image(cc{4},(121:1:120+surfcolors));
        set(cc{4},'XTick',1:(surfcolors-1)/6:surfcolors,'XTickLabel',{'0','1','2','3','4','5','          6 mm'},...
          'YTickLabel','','YTick',[],'TickLength',[0 0],'FontSize',fontsize,'FontWeight','Bold');
      catch
        cat_io_cprintf('warn','WARNING: Can''t display surface!\n',VT.fname);   
      end
    end
  end



  %% print subject report file as standard PDF/PNG/... file
  job.imgprint.type   = 'pdf';
  job.imgprint.dpi    = 600;
  job.imgprint.fdpi   = @(x) ['-r' num2str(x)];
  job.imgprint.ftype  = @(x) ['-d' num2str(x)];
  job.imgprint.fname  = fullfile(pth,reportfolder,['catreport_'  nam '.' job.imgprint.type]); 
  job.imgprint.fnamej = fullfile(pth,reportfolder,['catreportj_' nam '.jpg']);

  fgold.PaperPositionMode = get(fg,'PaperPositionMode');
  fgold.PaperPosition     = get(fg,'PaperPosition');
  fgold.resize            = get(fg,'resize');

  % it is necessary to change some figure properties especialy the fontsizes 
  set(fg,'PaperPositionMode','auto','resize','on','PaperPosition',[0 0 1 1]);
  for hti = 1:numel(htext), if htext(hti)>0, set(htext(hti),'Fontsize',fontsize*0.8); end; end
  for hti = 1:numel(cc), set(cc{hti},'Fontsize',fontsize*0.8); end;
 % warning off %#ok<WNOFF>
  print(fg, job.imgprint.ftype(job.imgprint.type), job.imgprint.fdpi(job.imgprint.dpi), job.imgprint.fname); 
  print(fg, job.imgprint.ftype('jpeg'), job.imgprint.fdpi(job.imgprint.dpi/2), job.imgprint.fnamej); 
 % warning on %#ok<WNON>
  for hti = 1:numel(htext), if htext(hti)>0, set(htext(hti),'Fontsize',fontsize); end; end
  for hti = 1:numel(cc), set(cc{hti},'Fontsize',fontsize); end; 
  set(fg,'PaperPositionMode',fgold.PaperPositionMode,'resize',fgold.resize,'PaperPosition',fgold.PaperPosition);
  try
    fprintf('Print ''Graphics'' figure to: \n  %s\n',job.imgprint.fname);% windows error?
  end

  %% reset colormap to the simple SPM like gray60 colormap
  if exist('hSD','var')
    % if there is a surface than we have to use the gray colormap also here
    % because the colorbar change!
    try 
      cat_surf_render2('ColourMap',hSD{1}.axis,gray(128));
      cat_surf_render2('Clim',hSD{1}.axis,[0 6]);
      axes(cc{4}); image(cc{4},0:60);
      set(cc{4},'XTick',max(1,0:10:60),'XTickLabel',{'0','1','2','3','4','5','          6 mm'},...
        'YTickLabel','','YTick',[],'TickLength',[0 0],'FontSize',fontsize,'FontWeight','Bold');
    end
  end

  % new colorscale
  cmap = gray(60); colormap(cmap); caxis([0,numel(cmap)]); 

  WMfactor0 = WMth * 4/3; %mean(res.mn(res.lkp==2)) * 4/3; 
  WMfactor1 = 4/3; 
  if exist('hho' ,'var'), spm_orthviews('window',hho ,[0 WMfactor0]); end
  if exist('hhm' ,'var'), spm_orthviews('window',hhm ,[0 WMfactor1]); end
  if exist('hhp0','var'), try, spm_orthviews('window',hhp0,[0 WMfactor1]); end; end
  
  
  %% change line style of TPM surf
  if job.extopts.expertgui>0 - showTPMsurf
    id = 1; 
    hM = findobj(st.vols{id}.ax{1}.cm,'Label','Mesh');
    UD = get(hM,'UserData');
    UD.width = [repmat(0.75,1,numel(UD.width) - numel(Psurf))  repmat(0.5,1,numel(Psurf))]; 
    UD.style = [repmat({'r--'},1,numel(UD.width) - numel(Psurf)) repmat({'k-'},1,numel(Psurf))];
    set( cclp,'Color', [1 0 0]);
    set(hM,'UserData',UD);
    spm_ov_mesh('redraw',id);
  end  
  
  warning('OFF','MATLAB:subscripting:noSubscriptsSpecified'); % jep off

end
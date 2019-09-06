function installMe( varargin )

debug = -1 ;
% process arguments
args = varargin;
nargs = length(args);
for i=1:2:nargs
    switch args{i}
        case 'debug', debug = args{i+1} ;
    end
end

% install current path
newPath = pwd ;
addpath(newPath) ;

newPath = sprintf( '%s/uHellinger', pwd ) ;
addpath(newPath) ;

newPath = sprintf( '%s/MDL', pwd ) ;
addpath(newPath) ;

newPath = sprintf( '%s/uEntropy', pwd ) ;
addpath(newPath) ;

newPath = sprintf( '%s/l2', pwd ) ;
addpath(newPath) ;

% install debug if required
installDebug( debug ) ;

% install other branches



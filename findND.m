function varargout=findND(X,varargin)
% Find non-zero elements in ND-arrays. Replicates all behavior from find.
%
% The syntax is equivalent to the built-in find, but extended to multi-dimensional input.
%
% The syntax with more than one input is present in the doc for R14 (Matlab 7.0), so R13 (Matlab
% 6.5) is the latest release without support for this syntax.
%
% [...] = findND(X,K) returns at most the first K indices. K must be a positive scalar of any type.
%
% [...] = findND(X,K,side) returns either the first K or the last K indices. The input side  must
% be a char, either 'first' or 'last'. The default behavior is 'first'.
%
% [I1,I2,I3,...,In] = findND(X,...) returns indices along all the dimensions of X.
%
% [I1,I2,I3,...,In,V] = findND(X,...) returns indices along all the dimensions of X, and
% additionally returns a vector containing the values.
%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%|                                                                         |%
%|  Version: 2.0.0                                                         |%
%|  Date:    2022-11-29                                                    |%
%|  Author:  H.J. Wisselink                                                |%
%|  Licence: CC by-nc-sa 4.0 ( creativecommons.org/licenses/by-nc-sa/4.0 ) |%
%|  Email = 'h_j_wisselink*alumnus_utwente_nl';                            |%
%|  Real_email = regexprep(Email,{'*','_'},{'@','.'})                      |%
%|                                                                         |%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%
% Tested on several versions of Matlab (ML 6.5 and onward) and Octave (4.4.1 and onward), and on
% multiple operating systems (Windows/Ubuntu/MacOS). You can see the full test matrix below.
% Compatibility considerations:
% - This is expected to work on all releases.
%
% /=========================================================================================\
% ||                     | Windows             | Linux               | MacOS               ||
% ||---------------------------------------------------------------------------------------||
% || Matlab R2022b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2022a       | W10: Pass           |                     |                     ||
% || Matlab R2021b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2021a       | W10: Pass           |                     |                     ||
% || Matlab R2020b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2020a       | W10: Pass           |                     |                     ||
% || Matlab R2019b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2019a       | W10: Pass           |                     |                     ||
% || Matlab R2018a       | W10: Pass           | Ubuntu 22.04: Pass  |                     ||
% || Matlab R2017b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2016b       | W10: Pass           | Ubuntu 22.04: Pass  | Monterey: Pass      ||
% || Matlab R2015a       | W10: Pass           | Ubuntu 22.04: Pass  |                     ||
% || Matlab R2013b       | W10: Pass           |                     |                     ||
% || Matlab R2012a       |                     | Ubuntu 22.04: Pass  |                     ||
% || Matlab R2011a       | W10: Pass           | Ubuntu 22.04: Pass  |                     ||
% || Matlab R2010b       |                     | Ubuntu 22.04: Pass  |                     ||
% || Matlab R2010a       | W7: Pass            |                     |                     ||
% || Matlab R2007b       | W10: Pass           |                     |                     ||
% || Matlab 7.1 (R14SP3) | XP: Pass            |                     |                     ||
% || Matlab 6.5 (R13)    | W10: Pass           |                     |                     ||
% || Octave 7.2.0        | W10: Pass           |                     |                     ||
% || Octave 6.2.0        | W10: Pass           | Ubuntu 22.04: Pass  | Catalina: Pass      ||
% || Octave 5.2.0        | W10: Pass           |                     |                     ||
% || Octave 4.4.1        | W10: Pass           |                     | Catalina: Pass      ||
% \=========================================================================================/

% Parse inputs.
if ~(isnumeric(X) || islogical(X)) || numel(X)==0
    error('HJW:findND:FirstInput',...
        'Expected first input (X) to be a non-empty numeric or logical array.')
end
switch nargin
    case 1 %[...] = findND(X);
        side = 'first';
        K = inf;
    case 2 %[...] = findND(X,K);
        side = 'first';
        K = varargin{1};
        if ~(isnumeric(K) || islogical(K)) || numel(K)~=1 || any(K<0)
            error('HJW:findND:SecondInput',...
                'Expected second input (K) to be a positive numeric or logical scalar.')
        end
    case 3 %[...] = FIND(X,K,'first');
        K = varargin{1};
        if ~(isnumeric(K) || islogical(K)) || numel(K)~=1 || any(K<0)
            error('HJW:findND:SecondInput',...
                'Expected second input (K) to be a positive numeric or logical scalar.')
        end
        side = varargin{2};
        if isa(side,'string') && numel(side)==1,side = char(side);end
        if ~isa(side,'char') || ~( strcmpi(side,'first') || strcmpi(side,'last'))
            error('HJW:findND:ThirdInput','Third input must be either ''first'' or ''last''.')
        end
        side = lower(side);
    otherwise
        error('HJW:findND:InputNumber','Incorrect number of inputs.')
end

% Parse outputs.
% Allowed outputs: 0, 1, nDims, nDims+1
if nargout>1 && nargout<ndims(X)
    error('HJW:findND:Output','Incorrect number of output arguments.')
end

persistent OldSyntax,if isempty(OldSyntax),OldSyntax = ifversion('<',7,'Octave','<',3);end

% Replicate the behavior of find by rounding nargout to 1 if it is 0.
varargout = cell(max(1,nargout),1);
if OldSyntax
    % The find(X,k,side) syntax was introduced in v7.
    if nargout>ndims(X)
        [ind,ignore,val] = find(X(:)); %#ok<ASGLU> (no tilde pre-R2009b)
        % X(:) converts X to a column vector. Treating X(:) as a matrix forces val to be the actual
        % value, instead of the column index.
        if length(ind)>K
            if strcmp(side,'first') % Select first K outputs.
                ind = ind(1:K);
                val = val(1:K);
            else                    % Select last K outputs.
                ind = ind((end-K+1):end);
                val = val((end-K+1):end);
            end
        end
        [varargout{1:(end-1)}] = ind2sub(size(X),ind);
        varargout{end} = val;
    else
        ind = find(X);
        if numel(ind)>K
            if strcmp(side,'first')
                % Select first K outputs.
                ind = ind(1:K);
            else
                % Select last K outputs.
                ind = ind((end-K+1):end);
            end
        end
        [varargout{:}] = ind2sub(size(X),ind);
    end
else
    if nargout>ndims(X)
        [ind,ignore,val] = find(X(:),K,side);%#ok<ASGLU>
        % X(:) converts X to a column vector. Treating X(:) as a matrix forces val to be the actual
        % value, instead of the column index.
        [varargout{1:(end-1)}] = ind2sub(size(X),ind);
        varargout{end} = val;
    else
        ind = find(X,K,side);
        [varargout{:}] = ind2sub(size(X),ind);
    end
end
end
function tf=ifversion(test,Rxxxxab,Oct_flag,Oct_test,Oct_ver)
%Determine if the current version satisfies a version restriction
%
% To keep the function fast, no input checking is done. This function returns a NaN if a release
% name is used that is not in the dictionary.
%
% Syntax:
%   tf = ifversion(test,Rxxxxab)
%   tf = ifversion(test,Rxxxxab,'Octave',test_for_Octave,v_Octave)
%
% Input/output arguments:
% tf:
%   If the current version satisfies the test this returns true. This works similar to verLessThan.
% Rxxxxab:
%   A char array containing a release description (e.g. 'R13', 'R14SP2' or 'R2019a') or the numeric
%   version (e.g. 6.5, 7, or 9.6).
% test:
%   A char array containing a logical test. The interpretation of this is equivalent to
%   eval([current test Rxxxxab]). For examples, see below.
%
% Examples:
% ifversion('>=','R2009a') returns true when run on R2009a or later
% ifversion('<','R2016a') returns true when run on R2015b or older
% ifversion('==','R2018a') returns true only when run on R2018a
% ifversion('==',9.9) returns true only when run on R2020b
% ifversion('<',0,'Octave','>',0) returns true only on Octave
% ifversion('<',0,'Octave','>=',6) returns true only on Octave 6 and higher
%
% The conversion is based on a manual list and therefore needs to be updated manually, so it might
% not be complete. Although it should be possible to load the list from Wikipedia, this is not
% implemented.
%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%|                                                                         |%
%|  Version: 1.1.2                                                         |%
%|  Date:    2022-09-16                                                    |%
%|  Author:  H.J. Wisselink                                                |%
%|  Licence: CC by-nc-sa 4.0 ( creativecommons.org/licenses/by-nc-sa/4.0 ) |%
%|  Email = 'h_j_wisselink*alumnus_utwente_nl';                            |%
%|  Real_email = regexprep(Email,{'*','_'},{'@','.'})                      |%
%|                                                                         |%
%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%/%
%
% Tested on several versions of Matlab (ML 6.5 and onward) and Octave (4.4.1 and onward), and on
% multiple operating systems (Windows/Ubuntu/MacOS). For the full test matrix, see the HTML doc.
% Compatibility considerations:
% - This is expected to work on all releases.

% The decimal of the version numbers are padded with a 0 to make sure v7.10 is larger than v7.9.
% This does mean that any numeric version input needs to be adapted. multiply by 100 and round to
% remove the potential for float rounding errors.
% Store in persistent for fast recall (don't use getpref, as that is slower than generating the
% variables and makes updating this function harder).
persistent  v_num v_dict octave
if isempty(v_num)
    % Test if Octave is used instead of Matlab.
    octave = exist('OCTAVE_VERSION', 'builtin');
    
    % Get current version number. This code was suggested by Jan on this thread:
    % https://mathworks.com/matlabcentral/answers/1671199#comment_2040389
    v_num = [100, 1] * sscanf(version, '%d.%d', 2);
    
    % Get dictionary to use for ismember.
    v_dict = {...
        'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;
        'R14SP3' 701;'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;
        'R2008a' 706;'R2008b' 707;'R2009a' 708;'R2009b' 709;'R2010a' 710;
        'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
        'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;
        'R2015b' 806;'R2016a' 900;'R2016b' 901;'R2017a' 902;'R2017b' 903;
        'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;'R2020a' 908;
        'R2020b' 909;'R2021a' 910;'R2021b' 911;'R2022a' 912;'R2022b' 913};
end

if octave
    if nargin==2
        warning('HJW:ifversion:NoOctaveTest',...
            ['No version test for Octave was provided.',char(10),...
            'This function might return an unexpected outcome.']) %#ok<CHARTEN>
        if isnumeric(Rxxxxab)
            v = 0.1*Rxxxxab+0.9*fix(Rxxxxab);v = round(100*v);
        else
            L = ismember(v_dict(:,1),Rxxxxab);
            if sum(L)~=1
                warning('HJW:ifversion:NotInDict',...
                    'The requested version is not in the hard-coded list.')
                tf = NaN;return
            else
                v = v_dict{L,2};
            end
        end
    elseif nargin==4
        % Undocumented shorthand syntax: skip the 'Octave' argument.
        [test,v] = deal(Oct_flag,Oct_test);
        % Convert 4.1 to 401.
        v = 0.1*v+0.9*fix(v);v = round(100*v);
    else
        [test,v] = deal(Oct_test,Oct_ver);
        % Convert 4.1 to 401.
        v = 0.1*v+0.9*fix(v);v = round(100*v);
    end
else
    % Convert R notation to numeric and convert 9.1 to 901.
    if isnumeric(Rxxxxab)
        v = 0.1*Rxxxxab+0.9*fix(Rxxxxab);v = round(100*v);
    else
        L = ismember(v_dict(:,1),Rxxxxab);
        if sum(L)~=1
            warning('HJW:ifversion:NotInDict',...
                'The requested version is not in the hard-coded list.')
            tf = NaN;return
        else
            v = v_dict{L,2};
        end
    end
end
switch test
    case '==', tf = v_num == v;
    case '<' , tf = v_num <  v;
    case '<=', tf = v_num <= v;
    case '>' , tf = v_num >  v;
    case '>=', tf = v_num >= v;
end
end


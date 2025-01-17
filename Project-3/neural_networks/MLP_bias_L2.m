function [f,g] = MLP_bias_L2(w,X,y,nHidden,nLabels,lambda)
% MLPCLASSIFICATIONLOSS_MAT does the same thing as MLPclassificationLoss,
% but computes as much by matrix as possible, which is very fast.
%
% Yuanbo Han, Dec. 5, 2017.

[nInstances, nVars] = size(X);
nHiddenLayers = length(nHidden);

% Form Weights
inputWeights = reshape(w(1:nVars*nHidden(1)),nVars,nHidden(1));
offset = nVars * nHidden(1);
hiddenWeights = cell(1, nHiddenLayers-1);
for h = 2:nHiddenLayers
    hiddenWeights{h-1} = reshape(...
        w(offset+1:offset+nHidden(h-1)*nHidden(h)),...
        nHidden(h-1), nHidden(h));
    offset = offset + nHidden(h-1) * nHidden(h);
end
outputWeights = w(offset+1:offset+nHidden(end)*nLabels);
outputWeights = reshape(outputWeights, nHidden(end), nLabels);

ip = cell(1, nHiddenLayers);
fp = cell(1, nHiddenLayers);
if nargout > 1
    % Form Gradient
    gInput = zeros(size(inputWeights));
    gHidden = cell(1, nHiddenLayers-1);
    for h = 2:nHiddenLayers
        gHidden{h-1} = zeros(size(hiddenWeights{h-1}));
    end
    gOutput = zeros(size(outputWeights));
    
    f = 0;
    
    % Compute Output
    for i = 1:nInstances
        ip{1} = X(i,:) * inputWeights;
        fp{1} = tanh(ip{1});
        for h = 2:length(nHidden)
            ip{h} = fp{h-1} * hiddenWeights{h-1};
            fp{h} = tanh(ip{h});
        end
        yhat = fp{end} * outputWeights;
        
        relativeErr = yhat - y(i,:);
        f = f + sum(relativeErr.^2);
        
        err = 2 * relativeErr;
        
        % Output Weights
        gOutput = gOutput + fp{end}' * err + lambda * outputWeights;
        % The bias need not be included in regularization.
        gOutput(1,:) = gOutput(1,:) - lambda * outputWeights(1,:);
        
        if nHiddenLayers > 1
            % Last Layer of Hidden Weights
            backprop = err' * sech(ip{end}).^2 .* outputWeights';
            tempW = hiddenWeights{end};
            tempG = gHidden{end} + fp{end-1}' * sum(backprop,1) + ...
                lambda * tempW;
            
            % The bias need not be included in regularization.
            tempG(1,:) = tempG(1,:) - lambda * tempW(1,:);
            gHidden{end} = tempG;
            
            backprop = sum(backprop,1);
            % Other Hidden Layers
            for h = length(nHidden)-2:-1:1
                backprop = (backprop * hiddenWeights{h+1}') .* ...
                    sech(ip{h+1}).^2;
                tempW = hiddenWeights{h};
                tempG = gHidden{h} + fp{h}' * backprop + ...
                    lambda * tempW;
                % The bias need not be included in regularization.
                tempG(1,:) = tempG(1,:) - lambda * tempW(1,:);
                gHidden{h} = tempG;
            end
            
            % Input Weights
            backprop = (backprop * hiddenWeights{1}') .* sech(ip{1}).^2;
            gInput = gInput + X(i,:)' * backprop + lambda * inputWeights;
            % The bias need not be included in regularization.
            gInput(1,:) = gInput(1,:) - lambda * inputWeights(1,:);
            
        else % nHiddenLayers == 1
            % Input Weights
            gInput = gInput + X(i,:)' * ...
                ( sech(ip{end}).^2 .* (outputWeights * err')' ) + ...
                lambda * inputWeights;
            % The bias need not be included in regularization.
            gInput(1,:) = gInput(1,:) - lambda * inputWeights(1,:);
        end
    end
    
    % Put Gradient into vector
    g = zeros(size(w));
    g(1:nVars*nHidden(1)) = gInput(:);
    offset = nVars*nHidden(1);
    for h = 2:nHiddenLayers
        g(offset+1:offset+nHidden(h-1)*nHidden(h)) = gHidden{h-1};
        offset = offset+nHidden(h-1)*nHidden(h);
    end
    g(offset+1:offset+nHidden(end)*nLabels) = gOutput(:);
    
    
else % nargout <= 1
    ip{1} = X * inputWeights;
    fp{1} = tanh(ip{1});
    for h = 2:nHiddenLayers
        ip{h} = fp{h-1} * hiddenWeights{h-1};
        fp{h} = tanh(ip{h});
    end
    yhat = fp{end} * outputWeights;
    
    relativeErr = yhat - y;
    f = sum(sum(relativeErr.^2));
end

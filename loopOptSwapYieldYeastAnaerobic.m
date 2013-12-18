function loopOptSwapYieldYeastAnaerobic

    cleaner = onCleanup(@() cleanup);
    global run status
    status = 'starting';
    run = 'optSwapYieldYeast';
    logFile = sprintf('optSwapYieldYeast_anaerobic_glucose_%s.tsv', ...
                      datestr(now, 'yy-mm-dd_HH_MM_SS'));
    global fileId
    fileId = fopen(logFile, 'a');
    fprintf(fileId, ['target\taerobic\tsubstrate\tnum swaps\tthko\' ...
                     'tf_k\tmax yield\tswaps\ttime (s)\n']);
    fclose(fileId);

    % only produce these at minimal levels
    necessary_ex = {'EX_ergst(e)', 'EX_zymst(e)', 'EX_hdcea(e)', ...
                    'EX_ocdca(e)', 'EX_ocdcea(e)', ...
                    'EX_ocdcya(e)'};

    % glc, D-xyl, gylc, L-arab
    substrates = {'EX_glc(e)'}; %{'EX_glc(e)', 'EX_xyl-D(e)'};
    aer = {'anaerobic'};
    swaps = [0, 1, 2];
    for i=1:length(substrates)
        for j=1:length(aer)
            [model, biomass] = setupModel('iMM904',substrates{i},aer{j},'nothko');
            soln_wt = optimizeCbModel(model);
            opt.minBiomass = 0.1*soln_wt.f;
            fprintf('minBiomass\t%.2f', opt.minBiomass);
            opt.nondefaultReactionBounds = cell(1, length(necessary_ex));
            % only allow the ammount of these exchanges necessary to sustain normal growth
            for z=1:length(necessary_ex)
                opt.nondefaultReactionBounds{z} = {necessary_ex{z}, soln_wt.x(ismember(model.rxns, necessary_ex{z})), 0};
            end
            for k=1:length(swaps)
                opt.thko = 'nothko';
                opt.substrate = substrates{i};
                opt.aerobicString = aer{j};
                opt.swapNum = swaps(k);
                opt.logFile = logFile;
                opt.modelname = 'iMM904';
                opt.targetRxns = {'EX_hdca(e)'};
                % opt.targetRxns = yeastTargets(opt.modelname);
                opt.dhRxns = yeastDhPool();
                runOptSwapYield(opt);
            end
        end
    end
end

function pool = yeastDhPool()
    pool = {'GAPD', ...
            'NADH2-u6cm', ...
            'ICDHy', ...
            'GLUDyi', ...
            'PGCD', ...
            'ALDD2y', ...
            'GND', ...
            'G6PDH2', ...
            'ASADi', ...
            'HSDxi', ...
            'IPMD', ...
            'AASAD2', ...
            'SACCD1', ...
            'SACCD2', ...
            'SHK3D', ...
            'G3PD1ir', ...
            'XYLR', ...
            'XYLTD_D', ...
            'ALCD2x', ...
            'GLUSx', ...
            'MDH', ...
            'GLYCDy'};
end

function targets = yeastTargets(modelName)
    model = loadModelNamed(modelName);
    targets = model.rxns(findExcRxns(model));
end
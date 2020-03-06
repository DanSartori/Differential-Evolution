%Differential Evolution algorithm
%Based on:
%Mallipedi, Suganthan - Differential evolution algorithm with ensemble of parameters and mutation strategies.pdf
%Brest, Greiner - Self-Adapting Control Parameters in Differential Evolution, A Comparative Study on Numerical Benchmark Problems

function [Xopt,Xgen,Fgen,CRgen,objf_perf_min]=jDE_best2(NP,n_gen,Finit,CRinit,Xbound,objf_var,objf_k)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameters

%Probability of F and CR adjustment
tau1=0.1;
tau2=0.1;

%Scale factor bounds
F_bound=[0.1 0.9];

%Number of population members to be combined for mutation (defined by the selected approach)
nr=4;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initial population of target vectors

%Number of parameters to be optimized
nX=size(Xbound,2);

%Define initial population of target vectors
Xinit=zeros(nX,NP);

for i=1:nX
	Xinit(i,:)=Xbound(1,i)+random('Uniform',0,1,[1 NP])*(Xbound(2,i)-Xbound(1,i));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimal paramaters search

%Initialization
X=Xinit;
Xopt=Xinit(:,1);
Xgen=zeros(nX,NP,n_gen);
F=Finit*ones(1,NP);
Ftry=zeros(1,NP);
Fgen=zeros(NP,n_gen);
CR=CRinit*ones(1,NP);
CRtry=zeros(1,NP);
CRgen=zeros(NP,n_gen);
V=zeros(nX,NP);
U=zeros(nX,NP);
objf_perf_min=zeros(objf_k.n_objf_perf,1);
f_min=Inf;
f_min_old=Inf;
df=100;
k_fmin=1;
ng=1;


%Until all generations are evaluated and the objective function continue decreasing
while ng<=n_gen && df>=objf_k.df_lim
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Mutation       
    
    %For each target vector X
    for j=1:NP
        
        %Find mutually esclusive integers r in the range [1 NP]
        
        %Initialization of the index of the random elements to be selected
        r=round(random('Uniform',1,NP))*ones(1,nr);
        
        %Initalization
        exit=0;
        k=2;
        
        while exit==0
            
            %Trial number
            r_try=round(random('Uniform',1,NP));
            
            %If the trial number is different to all the elements in r and to j
            if sum(r_try==r)==0 && r_try~=j
                
                %Assign new number
                r(k)=r_try;
                k=k+1;
                
                %If last element is found
                if k>nr
                    exit=1;
                end
            end
            
        end
        
        
        %Define scale factor
        
        %Generate random parameter index 
        randF=random('Uniform',0,1,[1 2]);     
        
        %Scale factor
        if randF(1)<tau1
            Ftry(j)=F_bound(1)+randF(2)*F_bound(2);
        else
            Ftry(j)=F(j);
        end 
                
        %Define mutant vector
        V(:,j)=Xopt+Ftry(j)*(X(:,r(1))-X(:,r(2)))+Ftry(j)*(X(:,r(3))-X(:,r(4)));
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Crossover - Binomial approach
        
    %For each element of target-mutant vector pair    
    for j=1:NP        
        
        %Define crossover rate
        
        %Generate random parameter index
        randCR=random('Uniform',0,1,[1 2]);
        
        %Crossover rate
        if randCR(1)<tau2
            CRtry(j)=randCR(2);
        else
            CRtry(j)=CR(j);
        end       
        
         
        %Generate random parameter index
        i_rand=round(random('Uniform',1,nX));
        
        %For each parameter target-mutant vector pair 
        for i=1:nX
            
            %Define trial vector
            if rand<=CRtry(j) || i==i_rand
                U(i,j)=V(i,j);
            else
                U(i,j)=X(i,j);
            end
            
            %Random reinitialization if boundaries are crossed
            if U(i,j)<Xbound(1,i) || U(i,j)>Xbound(2,i)
                U(i,j)=Xbound(1,i)+rand*(Xbound(2,i)-Xbound(1,i));
            end
            
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Objective function evaluation
    
    
    %Evaluate the objective function for each target-trial vector pair
    for j=1:NP
        
        %Evaluate the objective function
        [f_x,objf_out_x]=eval_obj_fun(X(:,j),objf_var,objf_k);
        [f_u,objf_out_u]=eval_obj_fun(U(:,j),objf_var,objf_k);
        
        
        %If objective function value reduces, replace the target vector with the trial vector and update parameters
        if f_u<f_x
            X(:,j)=U(:,j);
            F(j)=Ftry(j);
            CR(j)=CRtry(j);
        end
        
        
        %Update objective function values and parameters
        if f_u<f_x && f_u<f_min
            
            %Update minimum objective function values
            f_min=f_u;
            df=100*(f_min_old-f_min)/f_min;
            f_min_old=f_min;
            
            %Update optimal target vector
            Xopt=U(:,j);
            
            %Record objective function elements values
            objf_perf_min(:,k_fmin)=cell2mat(struct2cell(objf_out_u));
            
            %Update index
            k_fmin=k_fmin+1;
            
        elseif f_x<=f_u && f_x<f_min
            
            %Update minimum objective function values
            f_min=f_x;
            df=100*(f_min_old-f_min)/f_min;
            f_min_old=f_min;
            
            %Update optimal target vector
            Xopt=X(:,j);
            
            %Record objective function elements values
            objf_perf_min(:,k_fmin)=cell2mat(struct2cell(objf_out_x));
            
            %Update index
            k_fmin=k_fmin+1;
            
        end
        
    end
    
    
    %Record population at each generation
    Xgen(:,:,ng)=X;
        
    %Record scale factor and crossover rate at each generation
    Fgen(:,ng)=F;
    CRgen(:,ng)=CR;
    
    
    %Update iteration number
    ng=ng+1;
    
end


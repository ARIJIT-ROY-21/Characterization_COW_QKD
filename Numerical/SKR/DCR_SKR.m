clc; clear;
% parameters
mu = 0.5; % Mean Number of Photons/Pulse
alpha = 0.2; % Attenuation in fiber in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 1e9; % Bit Rate
L = 0:0.5:300; % Length of Fiber in Km
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(-0.2); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.2; % Efficiency of Detector
t_d = 10e-9; % Dead Time in Detector
t_BSE = 0.8; % Transmittance of Eve's BS
f_decoy = 0.2; % Probability used to generate the decoy state
duty_cycle_TTL = 0.75; % Duty cycle of TTL pulses
f = 1.16;
% Different Dark Count Probability/Pulse 
P_d_values = [1e-6 1e-7 1e-8 ];
lines = {'-','--','-.'};
figure(1);
hold on;
for k = 1:length(P_d_values)
    P_d = P_d_values(k);
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
%Channel transmittance
eta_channel = 10.^(- alpha * L /10);
Photon_count_after_channel = mu * 10.^(- alpha * L /10) * R_b;
%% DATA LINE %%
% After Beam Splitter
Photon_count_after_BS = mu * 10.^(- alpha * L /10)* R_b * t_B;
% Photon Counts considering the SPD efficiency and dark count rate
Photon_count_after_D_d = Photon_count_after_BS .* eta + P_d .* R_b;
% Effective time difference between two consecutive pulses at data line
effective_time_difference_D_d = 1./(Photon_count_after_D_d) + t_d;
% Considering the Duty Cycle of TTL Pulses at D_d
effective_counts_D_d = ((1./effective_time_difference_D_d)).* duty_cycle_TTL;
%% MONITORING LINE%%
% After Beam Splitter
Photon_count_after_BS = mu * 10.^(- alpha * L /10)* R_b * (1-t_B);
% Photon Counts after MZI
Photon_Count_MZI_Upper = loss_MZI * mu * 10.^(- alpha * L /10)*  R_b * (1-t_B) * ((1+ 1*exp(-(sigma.^2)./2) * cos(theta))/2);
Photon_Count_MZI_Lower = loss_MZI * mu * 10.^(- alpha * L /10)*  R_b * (1-t_B) * ((1- 1*exp(-(sigma.^2)./2) * cos(theta))/2);
% No. of Photons reach at the SPDs
Photon_Count_before_SPD_0 = Photon_Count_MZI_Upper;
Photon_Count_before_SPD_1 = Photon_Count_MZI_Lower;
% Photon Couts considering the SPD efficiency and dark count rate
Photon_Count_after_SPD_0 = Photon_Count_before_SPD_0 * eta + P_d .* R_b;
Photon_Count_after_SPD_1 = Photon_Count_before_SPD_1 * eta + P_d .* R_b;
% Effective time difference between two consecutive pulses
effective_time_difference_SPD_0 = 1./(Photon_Count_after_SPD_0) + t_d;
effective_time_difference_SPD_1 = 1./(Photon_Count_after_SPD_1) + t_d;
% Considering the Duty Cycle of TTL Pulses
effective_counts_SPD_0 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL;
effective_counts_SPD_1 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL;
% Considering the Probability factor
total_counts_D_M1 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL * (2.*f_decoy + (1-f_decoy).^2./2);
total_counts_D_M2 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL * (2.*f_decoy + (1-f_decoy).^2./2);
% Visibility
V = (total_counts_D_M1 - total_counts_D_M2)./(total_counts_D_M1 + total_counts_D_M2);
% Quantum Bit Error Rate in percentage
Q_0 = (1 - V)./2;
Q = (1 - V).*100./2;
% No of counts after Sifting
R_s = effective_counts_D_d * (1 - f_decoy);
% Eve's Information
I_Eve =  mu .* 10.^(- 0.2*1/10) .* (1 -  t_BSE) + (1 - V) .*(1 + exp(-mu .* eta_channel)) ./(2*exp(-mu .* eta_channel));
% Shanon Entropy
H2 = @(x) -(x .* log2(x) + (1 - x) .* log2(1 - x));
H2 = @(x) real((x==0 | x==1).*0 + (x>0 & x<1).*H2(x));
% Secret key rate/s
R = R_s .* (1 - f .* H2(Q_0) - I_Eve);
R(R < 1e-10) = eps;  
  R_all(k,:) = R;
    %% Plot
    semilogy(L,R,'LineStyle',lines{k},'LineWidth',2,'DisplayName',['P_d = 10^{' num2str(log10(P_d)) '} Hz']);
    set(gca, 'YScale', 'log');
end

xlabel('Length of Fiber (Km)', 'FontSize', 16,'FontWeight', 'bold');
ylabel('Secret Key Rate (bits/s)' , 'FontSize', 16,'FontWeight', 'bold');
grid on;
legend('Location','northeast');
xlim([0 300]);
ylim([1e0 1e8]);
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;
%% Inset Plot
ax_inset = axes('Position',[0.18 0.20 0.30 0.25]);
hold(ax_inset,'on');
for k = 1:length(P_d_values)
 semilogy(ax_inset, L, R_all(k,:),'LineStyle', lines{k},'LineWidth', 1.5);
 set(ax_inset, 'YScale', 'log');
end
xlim(ax_inset,[50 51]);
ylim(ax_inset,[2.45e6 2.60e6]);
grid(ax_inset,'on');
box(ax_inset,'on');
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;




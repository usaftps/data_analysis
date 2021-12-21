function [dvec,pvec,tvec,svec,rvec,gvec]=us76_1000(zvec,units)
% /////////////////////////////////////////////////////////////////////////
% //
% //        [d,p,t,s,r,g]=us76_1000(z)
% //        [d,p,t,s,r,g]=us76_1000(z,units)
% //
% // US Standard Atmosphere 1976 (NASA Marshall)
% // * Calculates the atmospheric properties density, pressure and  
% //   temperature with extensions up to 1000 km
% // * There are actually two atmosphere modeling algorithms in this 
% //   function, one for altitudes less than 86 kilometers and the other  
% //   for higher altitudes.
% // Source: NASA Marshall Space Flight Center
% //
% // Argument output:
% //					d= density - kg/m^3              {slug/ft^3} 
% //					p= static pressure - Pa          {lb/ft^2}
% //					t= temperature - degKelvin       {C}
% //					s= speed of sound - m/s          {knots} 
% //					r= radius from center of Earth, Re+z - km {ft}
% //					g= gravity at z [=G0*(R0/r)^2] - km/s^2   {ft/s^2}
% //
% // Argument input:
% //					z= Geometric altitude above S.L. - km {ft}
% //                units= 'english' or 'metric'; default is 'english'
% //
% // 040311 Adopted and included clarifying comments, PZi
% /////////////////////////////////////////////////////////////////////////
% /*
% 	$Log: us76.c,v $
%  * Revision 0.1  2002/03/26  17:07:42  adamswa
%  * J. McCarter
%  *
% */
%
% Converted to MATLAB by Maj Tim Jorris, AFIT/ENY, 2007/01/05
% * Improved speed, corrected indexing @ 1000 km , 2008/07/01
% * Added radius (r) output to have Earth radius in one location
% * vectorized, 6 times speed improvement, 2009/02/12

dvec=zeros(size(zvec)); pvec=dvec; tvec=dvec; svec=dvec;

%% 1976 US standard atmospheric model 
% int us76_nasa2002(
%    double  z,   /* altitude (km)        */
%    double* d,   /* density (kg/m^3)     */
%    double* p,   /* pressure (Pa)        */
%    double* t,   /* temperature (dKelvin)*/
%    double* s    /* speed of sound (m/s) */
% )
%    r= radius from center of Earth, Re+z - km
%    g= gravity at z [=G0*(R0/r)^2] - km/s^2

zs = [... %    /* altitude independent variable (km) */
      0.,       11.019, 20.063, 32.162, 47.35, ... 
      51.413,   71.802, 86.,    91.,    94.,   ... 
      97.,      100.,   103.,   106.,   108.,  ...
      110.,     112.,   115.,   120.,   125.,  ... 
      130.,     135.,   140.,   145.,   150.,  ... 
      155.,     160.,   165.,   170.,   180.,  ... 
      190.,     210.,   230.,   265.,   300.,  ... 
      350.,     400.,   450.,   500.,   550.,  ... 
      600.,     650.,   700.,   750.,   800.,  ... 
      850.,     900.,   950.,   1000., ...
   ];

tms = [ ...  % Temperature in K
      288.15,   216.65, 216.65, 228.65, 270.65, ...
      270.65,   214.65, 186.95, 186.87, 187.74, ...
      190.40,   195.08, 202.23, 212.89, 223.29, ...
      240.00,   264.00, 300.00, 360.00, 417.23, ...
      469.27,   516.59, 559.63, 598.78, 634.39, ...
      666.80,   696.29, 723.13, 747.57, 790.07, ...
      825.31,   878.84, 915.78, 955.20, 976.01, ...
      990.06,   995.83, 998.22, 999.24, 999.67, ...
      999.85,   999.93, 999.97, 999.99, 999.99, ...
      1000.,    1000.,  1000.,  1000. ...
   ];

wms = [ ... % Molecular Weight in ND
      28.9644,  28.9644,        28.9644,        28.9644,        28.9644,...
      28.9644,  28.9644,        28.9522,        28.8890,        28.7830,...
      28.6200,  28.3950,        28.1040,        27.7650,        27.5210,...
      27.2680,  27.0200,        26.6800,        26.2050,        25.8030,...
      25.4360,  25.0870,        24.7490,        24.4220,        24.1030,...
      23.7920,  23.4880,        23.1920,        22.9020,        22.3420,...
      21.8090,  20.8250,        19.9520,        18.6880,        17.7260,...
      16.7350,  15.9840,        15.2470,        14.3300,        13.0920,...
      11.5050,  9.7180,         7.9980,         6.5790,         5.5430,...
       4.8490,  4.4040,         4.1220,         3.9400...
   ];

ps = [ ... % Pressure in Pa = N/m^2
      1013.25,          226.32,         54.7487,        8.68014,    ...    
      1.10905,          0.66938,        0.039564,       3.7338e-03, ...
      1.5381e-03,       9.0560e-04,     5.3571e-04,     3.2011e-04, ...
      1.9742e-04,       1.2454e-04,     9.3188e-05,     7.1042e-05, ...
      5.5547e-05,       4.0096e-05,     2.5382e-05,     1.7354e-05, ...
      1.2505e-05,       9.3568e-06,     7.2028e-06,     5.6691e-06, ...
      4.5422e-06,       3.6930e-06,     3.0395e-06,     2.5278e-06, ...
      2.1210e-06,       1.5271e-06,     1.1266e-06,     6.4756e-07, ...
      3.9276e-07,       1.7874e-07,     8.7704e-08,     3.4498e-08, ...
      1.4518e-08,       6.4468e-09,     3.0236e-09,     1.5137e-09, ...
      8.2130e-10,       4.8865e-10,     3.1908e-10,     2.2599e-10, ...  
      1.7036e-10,       1.3415e-10,     1.0873e-10,     8.9816e-11, ...
      7.5138e-11 ...
   ];
% RE=6378.1370014; GO=ucon(32.174,'ft_sec2','m_sec2');
ro  = 6356.766;       % /* radius of Earth - km */
go  = 9.80665;        % /* nominal gravitational acceleration - m/s^2  */
% ro=RE; go=GO;
wmo = 28.9644;        % /* molecular weight - ND */
rs  = 8314.32;        % /* universal gas constant (m^2/s^2) (gram/mole) / (degree Kelvin) */

rvec=zvec+ro; gvec=go/1000*(ro./rvec).^2; % km and km/s^2

for i=0:48  % 0 is error checking, 48 regions between 49 fence posts
    % z=zvec(k);

    %   /* check to see if input altitude is in range, return 1 if not */
    if i==0
        id_low = (zvec < -4);
        id_hi  = (zvec > 1000);
        if (nnz(id_low)+nnz(id_hi)) == 0 
            continue
        else
            % z < -4. || z > 1000.
            % -3 km allows a dip without warning.  If iterating or integrating,
            % allows you to "find" zero without warning. Beyond that there is
            % likely a runaway trajectory, i.e. warning is justified.
            t  = 0.;
            p  = 0.;
            d  = 0.;
            s  = 0.;
            wm = 0.;
            % return 1;
            % warning('Input altitude is out of range')
            if nnz(id_low) > 0
                warning(sprintf('There were %d altitudes low out of range',sum(id_low)))
                tvec(id_low)=t; pvec(id_low)=p; dvec(id_low)=d; svec(id_low)=s;
            end
            if nnz(id_hi) > 0
                warning(sprintf('There were %d altitudes high out of range',sum(id_hi)))
                tvec(id_low)=t; pvec(id_low)=p; dvec(id_low)=d; svec(id_low)=s;
            end
            continue
        end
    elseif i < 8 % less than 86 km
        
%     %  /* bisection search for i such that zs[i] <= z < zs[i+1] */
%     i=1; j=49;                           % setting up for binary search
%     while true
%         kk=round( (i+j)/2 );
%         if (z <= zs(kk))
%             j=kk;
%         else
%             i=kk;
%         end
%         if (j <= i+1) break, end
%     end
% 
% 
%     if( i < 8 ) % C-code was base 0, hence c-code 7 if MATLAB 8
        if i == 1
            id = (zvec < zs(i+1));
        elseif i == 7
            id = (zs(i) <= zvec & zvec <= zs(i+1));
%         elseif i == 9
%             id = (zs(i) < zvec & zvec < zs(i+1));
        else
            id = (zs(i) <= zvec & zvec < zs(i+1));
        end
        if nnz(id)==0, continue, end
        z  = zvec(id);
        zl = ro * zs(i  )/(ro + zs(i  ));
        zu = ro * zs(i+1)/(ro + zs(i+1));
        wm = wmo;
        ht = (ro * z)./(ro + z);
        g = (tms(i+1)-tms(i))/(zu-zl); % Temp lapse rate (K/km)

        if(g < 0. || g > 0.)
        % p=ps(i)*pow((tms(i)/(tms(i)+g*(ht-zl))),((go*wmo)/(rs*g*0.001)))*100.;
            p=ps(i)*((tms(i)./(tms(i)+g*(ht-zl))).^((go*wmo)/(rs*g*0.001)))*100.;
        else
            p=ps(i) * exp(-(go*wmo*(ht*1000.-zl*1000.))./(rs*tms(i))) * 100.;
        end
        t = tms(i) + g * (ht-zl);
    else
        if i < 48
            id = (zs(i) <= zvec & zvec < zs(i+1));
        else
            id = (zs(i) <= zvec); % Capture all greater
        end
        if nnz(id)==0, continue, end
        z  = zvec(id);
        if(i == 8)
            t = tms(9);
        elseif (i >= 9 && i < 16)
         % *t = 263.1905-76.3232 * sqrt(1.-pow((z-91.)/19.9429,2.));
            t = 263.1905-76.3232 * sqrt(1.-((z-91.)/19.9429).^2.);
        elseif (i >= 16 && i < 19)
            t = 240. + 12. * (z-110.);
        elseif (i >= 19)
            xi = (z-120.) * (ro + 120.)./(ro + z);
            t = 1000.-640. * exp(-0.01875 * xi);
        end

        j = i;

        if (i == 48), j = i-1; end

        z0 = zs(j  );
        z1 = zs(j+1);
        z2 = zs(j+2);
        wma = wms(j  ) * (z-z1) .* (z-z2)/((z0-z1) * (z0-z2)) + ...
            wms(j+1) * (z-z0) .* (z-z2)/((z1-z0) * (z1-z2)) + ...
            wms(j+2) * (z-z0) .* (z-z1)/((z2-z0) * (z2-z1));
        alp0 = log(ps(j));
        alp1 = log(ps(j+1));
        alp2 = log(ps(j+2));
        alpa = alp0 * (z-z1) .* (z-z2)/((z0-z1) * (z0-z2)) + ...
            alp1 * (z-z0) .* (z-z2)/((z1-z0) * (z1-z2)) + ...
            alp2 * (z-z0) .* (z-z1)/((z2-z0) * (z2-z1));
        alpb = alpa;
        wmb = wma;

        if (i~=8 && i ~= 48)
            j = j-1;
            z0 = zs(j  );
            z1 = zs(j+1);
            z2 = zs(j+2);
            alp0 = log(ps(j  ));
            alp1 = log(ps(j+1));
            alp2 = log(ps(j+2));
            alpb = alp0 * (z-z1) .* (z-z2)/((z0-z1) * (z0-z2)) + ...
                alp1 * (z-z0) .* (z-z2)/((z1-z0) * (z1-z2)) + ...
                alp2 * (z-z0) .* (z-z1)/((z2-z0) * (z2-z1));
            wmb =  wms(j  ) * (z-z1) .* (z-z2)/((z0-z1) * (z0-z2)) + ...
                wms(j+1) * (z-z0) .* (z-z2)/((z1-z0) * (z1-z2)) + ...
                wms(j+2) * (z-z0) .* (z-z1)/((z2-z0) * (z2-z1));
        end

        p = 100. * exp((alpa + alpb)/2.);
        wm = (wma + wmb)/2.;
    end
    d = (wm .* p)./(rs * t);
    s = sqrt(1.4 * p ./ d);
    tvec(id)=t; pvec(id)=p; dvec(id)=d; svec(id)=s;
end

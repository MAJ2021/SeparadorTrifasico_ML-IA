model Separadores_V48_55
  parameter Real V_sep = 17.0;
  parameter Real Qin_agua = 2000/86400;
  parameter Real Qin_oil  = 450/86400;
  parameter Real Qin_gas  = 4000/86400;

  // Inventario inicial operativo
  Real V_agua1(start=8), V_oil1(start=4), Pgas1(start=3.5e5);
  Real V_agua2(start=8), V_oil2(start=4), Pgas2(start=3.5e5);

  // Niveles %
  Real nivel_total1, nivel_oil1;
  Real nivel_total2, nivel_oil2;

  // Controladores PID con anti-windup
  Real error_total1, error_oil1, integral_total1(start=0), integral_oil1(start=0);
  Real error_total2, error_oil2, integral_total2(start=0), integral_oil2(start=0);

  Real apertura_total1(start=0.2), apertura_oil1(start=0.2);
  Real apertura_total2(start=0.2), apertura_oil2(start=0.2);

  // Caudales de salida
  Real Qout_total1, Qout_oil1, Qout_gas1;
  Real Qout_total2, Qout_oil2, Qout_gas2;

  // Setpoints
  parameter Real sp_total = 75;
  parameter Real sp_oil   = 54;
  parameter Real Kp = 0.8;
  parameter Real Ki = 1e-3;

  // Coeficientes de válvula (ajustables con Cv real)
  parameter Real Cv_total = 0.02;
  parameter Real Cv_oil   = 0.005;

equation
  // Balance separador 1
  der(V_agua1) = Qin_agua/2 - Qout_total1;
  der(V_oil1)  = Qin_oil/2  - Qout_oil1;
  der(Pgas1)   = Qin_gas/2 - Qout_gas1;

  nivel_total1 = (V_agua1+V_oil1)/V_sep*100;
  nivel_oil1   = V_oil1/V_sep*100;

  error_total1 = sp_total - nivel_total1;
  error_oil1   = sp_oil   - nivel_oil1;

  // Anti-windup: integral limitada
  der(integral_total1) = if apertura_total1 < 1 and apertura_total1 > 0 then error_total1 else 0;
  der(integral_oil1)   = if apertura_oil1   < 1 and apertura_oil1   > 0 then error_oil1   else 0;

  apertura_total1 = min(max(Kp*error_total1 + Ki*integral_total1,0),1);
  apertura_oil1   = min(max(Kp*error_oil1   + Ki*integral_oil1,0),1);

  // Caudales dependientes de presión y nivel
  Qout_total1 = min(apertura_total1*Cv_total*sqrt(Pgas1/1e5), max(V_agua1,0));
  Qout_oil1   = min(apertura_oil1*Cv_oil*sqrt(Pgas1/1e5), max(V_oil1,0));
  Qout_gas1   = max((Pgas1-1e5)/1e5*0.05,0);

  // Balance separador 2
  der(V_agua2) = Qin_agua/2 - Qout_total2;
  der(V_oil2)  = Qin_oil/2  - Qout_oil2;
  der(Pgas2)   = Qin_gas/2 - Qout_gas2;

  nivel_total2 = (V_agua2+V_oil2)/V_sep*100;
  nivel_oil2   = V_oil2/V_sep*100;

  error_total2 = sp_total - nivel_total2;
  error_oil2   = sp_oil   - nivel_oil2;

  der(integral_total2) = if apertura_total2 < 1 and apertura_total2 > 0 then error_total2 else 0;
  der(integral_oil2)   = if apertura_oil2   < 1 and apertura_oil2   > 0 then error_oil2   else 0;

  apertura_total2 = min(max(Kp*error_total2 + Ki*integral_total2,0),1);
  apertura_oil2   = min(max(Kp*error_oil2   + Ki*integral_oil2,0),1);

  Qout_total2 = min(apertura_total2*Cv_total*sqrt(Pgas2/1e5), max(V_agua2,0));
  Qout_oil2   = min(apertura_oil2*Cv_oil*sqrt(Pgas2/1e5), max(V_oil2,0));
  Qout_gas2   = max((Pgas2-1e5)/1e5*0.05,0);
end Separadores_V48_55;

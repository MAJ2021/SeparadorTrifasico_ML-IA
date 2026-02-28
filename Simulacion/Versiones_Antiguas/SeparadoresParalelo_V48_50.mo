model SeparadoresParalelo_V48_50
  parameter Real V_sep = 17.0;
  parameter Real Qin_agua = 2000/86400;   // ~0.0231 m3/s
  parameter Real Qin_oil  = 450/86400;    // ~0.0052 m3/s
  parameter Real Qin_gas  = 4000/86400;   // ~0.0463 m3/s

  // Estados dinámicos
  Real V_agua1(start=0), V_oil1(start=0);
  Real V_agua2(start=0), V_oil2(start=0);

  // Niveles en porcentaje
  Real nivel_total1, nivel_oil1;
  Real nivel_total2, nivel_oil2;

  // Controladores
  Real error_total1, error_oil1;
  Real error_total2, error_oil2;
  Real integral_total1(start=0), integral_oil1(start=0);
  Real integral_total2(start=0), integral_oil2(start=0);

  Real apertura_valvula_total1, apertura_valvula_oil1;
  Real apertura_valvula_total2, apertura_valvula_oil2;

  // Caudales de salida
  Real Qout_total1, Qout_oil1;
  Real Qout_total2, Qout_oil2;

  // Parámetros PID
  parameter Real sp_total = 75;
  parameter Real sp_oil   = 54;
  parameter Real Kp = 0.5;
  parameter Real Ki = 1e-3;

equation
  // Balance separador 1
  der(V_agua1) = Qin_agua/2 - Qout_total1;
  der(V_oil1)  = Qin_oil/2  - Qout_oil1;

  nivel_total1 = (V_agua1+V_oil1)/V_sep*100;
  nivel_oil1   = V_oil1/V_sep*100;

  error_total1 = sp_total - nivel_total1;
  error_oil1   = sp_oil   - nivel_oil1;

  der(integral_total1) = error_total1;
  der(integral_oil1)   = error_oil1;

  apertura_valvula_total1 = min(max(Kp*error_total1 + Ki*integral_total1,0),1);
  apertura_valvula_oil1   = min(max(Kp*error_oil1   + Ki*integral_oil1,0),1);

  Qout_total1 = min(apertura_valvula_total1*0.02, V_agua1); // coef ajustable
  Qout_oil1   = min(apertura_valvula_oil1*0.005, V_oil1);

  // Balance separador 2 (idéntico)
  der(V_agua2) = Qin_agua/2 - Qout_total2;
  der(V_oil2)  = Qin_oil/2  - Qout_oil2;

  nivel_total2 = (V_agua2+V_oil2)/V_sep*100;
  nivel_oil2   = V_oil2/V_sep*100;

  error_total2 = sp_total - nivel_total2;
  error_oil2   = sp_oil   - nivel_oil2;

  der(integral_total2) = error_total2;
  der(integral_oil2)   = error_oil2;

  apertura_valvula_total2 = min(max(Kp*error_total2 + Ki*integral_total2,0),1);
  apertura_valvula_oil2   = min(max(Kp*error_oil2   + Ki*integral_oil2,0),1);

  Qout_total2 = min(apertura_valvula_total2*0.02, V_agua2);
  Qout_oil2   = min(apertura_valvula_oil2*0.005, V_oil2);
end SeparadoresParalelo_V48_50;

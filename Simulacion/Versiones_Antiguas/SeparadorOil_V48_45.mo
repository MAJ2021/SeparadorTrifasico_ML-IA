model SeparadorOil_V48_45
  // Parámetros de planta
  parameter Real V_sep   = 17.0;              // volumen separador [m3]
  parameter Real Qin_base = 450/86400;        // entrada oil ~0.0052 m3/s
  parameter Real Cv = 0.0033;                 // coef válvula [m3/s]/√bar
  parameter Real P_sep = 3.5;                 // presión separador [bar]
  parameter Real P_linea = 1.0;               // presión línea salida [bar]

  // Estados dinámicos
  Real V_oil(start=0.0);                      // arranque desde cero
  Real V_oil_pct;
  Real error;
  Real integralError(start=0);
  Real valveOpening;
  Real Qin, Qout;
  Real deltaP;

  // Control PID
  parameter Real spOil_pct = 54;              // setpoint nivel oil
  parameter Real Kp = 0.1;                    // proporcional más agresivo
  parameter Real Ki = 5e-4;                   // integral moderada

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = noEvent(min(max((V_oil/V_sep)*100,0),100));

  // Error y control PI
  error = spOil_pct - V_oil_pct;
  der(integralError) = error;

  // Apertura de válvula (0–1)
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Diferencia de presión
  deltaP = noEvent(max(P_sep - P_linea,0));

  // Caudal de salida limitado por inventario
  Qout = noEvent(min(Cv * valveOpening * sqrt(deltaP), V_oil));

  // Entrada fija
  Qin = Qin_base;
end SeparadorOil_V48_45;

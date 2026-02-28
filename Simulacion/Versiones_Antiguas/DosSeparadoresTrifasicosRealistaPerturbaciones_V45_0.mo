model DosSeparadoresTrifasicosRealistaPerturbaciones_V45_0
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 400/86400 "Caudal base de petróleo m3/s";
  parameter Real tauRec = 700 "Constante de tiempo de recuperación";
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilOut;

  Modelica.Blocks.Continuous.PID pidOilOut(k=0.02, Ti=3000, Td=0.1);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  Real V_oil_pct, spOil_pct;
  Real spDynamic;
  Real osc;

equation
  // Setpoint fijo en 54%
  spDynamic = 0.54*V_sep;

  // Balance dinámico
  der(V_oil) = Qin_oil - Qout_oil - (V_oil - spDynamic)/tauRec;

  // PID con retardo
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  // Entrada y salida según fases
  if time < 1800 then
    // Meseta inicial en 54%
    Qin_oil = Qin_oil_base;
    Qout_oil = Qin_oil;
  elseif time >= 1800 and time < 3600 then
    // Perturbación exceso → sube a 90%
    Qin_oil = Qin_oil_base*2.5;
    Qout_oil = valveOilOut * Qin_oil_base;
  elseif time >= 3600 and time < 5400 then
    // Meseta estable en 54%
    Qin_oil = Qin_oil_base;
    Qout_oil = Qin_oil;
  elseif time >= 5400 and time < 7200 then
    // Perturbación déficit → baja a 20%
    Qin_oil = Qin_oil_base*0.05;
    Qout_oil = valveOilOut * Qin_oil_base * 2.0;
  else
    // Meseta final en 54%
    Qin_oil = Qin_oil_base;
    Qout_oil = Qin_oil;
  end if;

  // Oscilaciones suaves
  osc = 0.02*sin(time/137) + 0.015*sin(time/271);

  // Variables en porcentaje
  V_oil_pct = V_oil / V_sep * 100;
  spOil_pct = spDynamic / V_sep * 100;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V45_0;

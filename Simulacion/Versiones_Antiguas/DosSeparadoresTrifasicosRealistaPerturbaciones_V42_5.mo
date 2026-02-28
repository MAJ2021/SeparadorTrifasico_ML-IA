model DosSeparadoresTrifasicosRealistaPerturbaciones_V42_5
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 456/86400 "Caudal base de aceite m3/s";
  parameter Real tauRec = 700 "Constante de tiempo de recuperación";
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  Real V_oil(start=0.54*V_sep, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilIn, valveOilOut;

  Modelica.Blocks.Continuous.PID pidOilOut(k=0.005, Ti=10000);
  Modelica.Blocks.Continuous.PID pidOilIn(k=0.005, Ti=10000);

  Modelica.Blocks.Continuous.FirstOrder delayOilIn(T=Tdelay);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  Real V_oil_pct, spOil_pct, valveOilIn_pct, valveOilOut_pct;
  Real spDynamic;
  Real osc;

equation
  // Balance con recuperación activa fuera de meseta
  der(V_oil) = if (time >= 10800 and time < 12600) then
                 Qin_oil - Qout_oil
               else
                 (Qin_oil - Qout_oil) - (V_oil - spDynamic)/tauRec;

  // Setpoint dinámico con meseta intermedia de 30 min
  if time >= 7200 and time < 10800 then
    spDynamic = 0.90*V_sep;   // exceso
  elseif time >= 10800 and time < 12600 then
    spDynamic = 0.54*V_sep;   // meseta intermedia (30 min)
  elseif time >= 12600 and time < 14400 then
    spDynamic = 0.20*V_sep;   // déficit
  else
    spDynamic = 0.54*V_sep;   // meseta final
  end if;

  // PID con retardo
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  pidOilIn.u = (spDynamic/V_sep*100) - (V_oil/V_sep*100);
  delayOilIn.u = pidOilIn.y;
  valveOilIn = min(max(delayOilIn.y, 0), 1);

  // Entrada
  if (time >= 10800 and time < 12600) then
    Qin_oil = Qin_oil_base;   // entrada fija en meseta intermedia
  elseif (time >= 12600 and time < 14400) then
    Qin_oil = Qin_oil_base*0.05; // déficit
  elseif (time >= 7200 and time < 10800) then
    Qin_oil = Qin_oil_base*5.0;  // exceso
  else
    Qin_oil = valveOilIn * Qin_oil_base;
  end if;

  // Oscilaciones pseudo-aleatorias
  osc = 0.05*sin(time/137) + 0.03*sin(time/271) + 0.02*sin(time/59);

  // Salida
  if (time >= 10800 and time < 12600) then
    // Meseta intermedia: salida ≈ entrada con oscilaciones moderadas
    Qout_oil = Qin_oil * (1 + osc*0.1);
  elseif (time >= 12600 and time < 14400) then
    // Déficit
    Qout_oil = (V_oil/V_sep) * Qin_oil_base;
  elseif (time >= 14400) then
    // Meseta final
    Qout_oil = Qin_oil * (1 + osc*0.15);
  else
    // Exceso y normal
    Qout_oil = max(0, valveOilOut * (V_oil/V_sep) * (2*Qin_oil_base));
  end if;

  // Variables en porcentaje
  V_oil_pct       = V_oil / V_sep * 100;
  spOil_pct       = spDynamic / V_sep * 100;
  valveOilIn_pct  = valveOilIn * 100;
  valveOilOut_pct = valveOilOut * 100;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V42_5;

// Consultas MongoDB

const marazulDb = db.getSiblingDB('marazul_field_logs');

printjson(marazulDb.field_diaries.insertMany([
  {
    _id: 1,
    id_trip: 1,
    recorded_at: ISODate('2026-01-07T18:30:00.000Z'),
    notes: 'Oleaje moderado; se redujo el tiempo de faena.',
    weather: { sky: 'Parcialmente nublado', wave_height_m: 1.2 },
    sightings: [{ animal: 'Delfín', count: 4 }]
  },
  {
    _id: 2,
    id_trip: 2,
    recorded_at: ISODate('2026-01-11T18:30:00.000Z'),
    notes: 'Viento fuerte al regreso; sin daños en la embarcación.',
    weather: { wind: 'Fuerte', wave_height_m: 1.8 }
  },
  {
    _id: 3,
    id_trip: 3,
    recorded_at: ISODate('2026-01-15T18:30:00.000Z'),
    notes: 'Agua turbia cerca de la costa; el motor presentó una falla.',
    mechanical_failure: {
      component: 'Motor',
      description: 'Sobrecalentamiento durante el regreso',
      action: 'Se redujo la velocidad y se solicitó revisión'
    }
  },
  {
    _id: 4,
    id_trip: 4,
    recorded_at: ISODate('2026-01-19T18:30:00.000Z'),
    notes: 'Mar tranquilo y buena visibilidad; se perdió una red.',
    gear_loss: {
      equipment: 'Red de pesca',
      quantity: 1,
      cause: 'Enganche en una estructura sumergida'
    }
  },
  {
    _id: 5,
    id_trip: 5,
    recorded_at: ISODate('2026-01-23T18:30:00.000Z'),
    notes: 'Oleaje moderado; se redujo el tiempo de faena.',
    weather: { wave_height_m: 1.4 },
    mechanical_failure: {
      component: 'Sistema de combustible',
      description: 'Obstrucción del filtro',
      action: 'Limpieza del filtro'
    },
    gear_loss: {
      equipment: 'Red de pesca',
      quantity: 1,
      cause: 'Rotura durante la recuperación'
    }
  }
]));

// 1. Recuperar los cinco diarios.
printjson(marazulDb.field_diaries.find().sort({ _id: 1 }).toArray());

// 2. Jornadas con fallas mecanicas: 3 y 5.
printjson(marazulDb.field_diaries.find(
  { mechanical_failure: { $exists: true } },
  { _id: 0, id_trip: 1, notes: 1, mechanical_failure: 1 }
).sort({ id_trip: 1 }).toArray());

// 3. Jornadas con perdida de redes: 4 y 5.
printjson(marazulDb.field_diaries.find(
  { 'gear_loss.equipment': 'Red de pesca' },
  { _id: 0, id_trip: 1, notes: 1, gear_loss: 1 }
).sort({ id_trip: 1 }).toArray());

// 4. Jornadas con falla mecanica o perdida de redes: 3, 4 y 5.
printjson(marazulDb.field_diaries.find(
  {
    $or: [
      { mechanical_failure: { $exists: true } },
      { 'gear_loss.equipment': 'Red de pesca' }
    ]
  },
  { _id: 0, id_trip: 1, mechanical_failure: 1, gear_loss: 1 }
).sort({ id_trip: 1 }).toArray());

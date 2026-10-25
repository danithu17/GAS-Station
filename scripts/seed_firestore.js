const fs = require('fs');
const path = require('path');

async function seed() {
  const configPath = path.join(process.env.USERPROFILE, '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    console.error('Firebase tools config not found.');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  let token = config.tokens?.access_token;

  const projectId = 'chat-3af33';
  const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/stations`;

  const stations = [
    {
      id: 'station_colombo_03_litro',
      name: 'Litro Gas Point - Kollupitiya',
      brand: 'litro',
      address: '284 Galle Road, Colombo 03',
      town: 'Colombo',
      latitude: 6.9068,
      longitude: 79.8516,
      status: 'available',
      queueCondition: 'short',
      cylinders: { '12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false },
      reportCount: 38,
      contactNumber: '+94 11 257 3290',
      notes: '12.5kg domestic available. Fresh truck arrived at 4:30 PM.',
    },
    {
      id: 'station_rajagiriya_laugfs',
      name: 'Laugfs Gas Super Station - Rajagiriya',
      brand: 'laugfs',
      address: '512 Sri Jayawardenepura Mawatha, Rajagiriya',
      town: 'Rajagiriya',
      latitude: 6.9082,
      longitude: 79.8967,
      status: 'available',
      queueCondition: 'moderate',
      cylinders: { '12.5kg': true, '5kg': false, '2.3kg': false, '37.5kg': true },
      reportCount: 52,
      contactNumber: '+94 11 545 5600',
      notes: 'Domestic 12.5kg and commercial 37.5kg in stock. Queue moving fast.',
    },
    {
      id: 'station_dehiwala_litro',
      name: 'Litro Gas Dealer - Dehiwala Junction',
      brand: 'litro',
      address: '148 Hill Street, Dehiwala-Mount Lavinia',
      town: 'Dehiwala',
      latitude: 6.8524,
      longitude: 79.8665,
      status: 'outOfStock',
      queueCondition: 'long',
      cylinders: { '12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false },
      reportCount: 19,
      contactNumber: '+94 11 271 4455',
      notes: 'Sold out by 3 PM. Next delivery expected tomorrow morning.',
    },
    {
      id: 'station_nugegoda_laugfs',
      name: 'Laugfs Express Depot - Nugegoda',
      brand: 'laugfs',
      address: '76 High Level Road, Nugegoda',
      town: 'Nugegoda',
      latitude: 6.8722,
      longitude: 79.8920,
      status: 'available',
      queueCondition: 'short',
      cylinders: { '12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false },
      reportCount: 64,
      contactNumber: '+94 11 282 3411',
      notes: 'Ample 5kg and 12.5kg cylinders. No line currently.',
    },
    {
      id: 'station_kandy_litro',
      name: 'Litro Gas Central Hub - Kandy City',
      brand: 'litro',
      address: '42 William Gopallawa Mawatha, Kandy',
      town: 'Kandy',
      latitude: 7.2906,
      longitude: 80.6337,
      status: 'available',
      queueCondition: 'moderate',
      cylinders: { '12.5kg': true, '5kg': true, '2.3kg': false, '37.5kg': false },
      reportCount: 41,
      contactNumber: '+94 81 222 7890',
      notes: 'Token system active. Around 20 people waiting.',
    },
    {
      id: 'station_gampaha_laugfs',
      name: 'Laugfs Gas Distributor - Gampaha',
      brand: 'laugfs',
      address: '19 Miriswatta Road, Gampaha',
      town: 'Gampaha',
      latitude: 7.0873,
      longitude: 79.9945,
      status: 'unverified',
      queueCondition: 'short',
      cylinders: { '12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false },
      reportCount: 7,
      contactNumber: '+94 33 222 1450',
      notes: 'Awaiting distributor confirmation. Please verify if visiting.',
    },
    {
      id: 'station_negombo_litro',
      name: 'Litro Gas Coastal Center - Negombo',
      brand: 'litro',
      address: '89 Colombo Road, Negombo',
      town: 'Negombo',
      latitude: 7.2008,
      longitude: 79.8736,
      status: 'available',
      queueCondition: 'short',
      cylinders: { '12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': true },
      reportCount: 30,
      contactNumber: '+94 31 223 4567',
      notes: 'Full stock across all cylinder types.',
    },
    {
      id: 'station_galle_litro',
      name: 'Litro Gas Outlet - Galle Fort Entrance',
      brand: 'litro',
      address: '110 Main Street, Galle',
      town: 'Galle',
      latitude: 6.0535,
      longitude: 80.2210,
      status: 'available',
      queueCondition: 'moderate',
      cylinders: { '12.5kg': true, '5kg': false, '2.3kg': false, '37.5kg': false },
      reportCount: 22,
      contactNumber: '+94 91 224 8900',
      notes: '12.5kg cylinders available. Limit 1 per household.',
    },
    {
      id: 'station_battaramulla_laugfs',
      name: 'Laugfs Gas Service Hub - Battaramulla',
      brand: 'laugfs',
      address: '320 Pannipitiya Road, Battaramulla',
      town: 'Battaramulla',
      latitude: 6.8997,
      longitude: 79.9234,
      status: 'available',
      queueCondition: 'short',
      cylinders: { '12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false },
      reportCount: 75,
      contactNumber: '+94 11 288 9200',
      notes: 'Well organized drive-through pickup. Quick queue.',
    },
    {
      id: 'station_kurunegala_litro',
      name: 'Litro Gas Distribution Point - Kurunegala',
      brand: 'litro',
      address: '55 Dambulla Road, Kurunegala',
      town: 'Kurunegala',
      latitude: 7.4863,
      longitude: 80.3623,
      status: 'outOfStock',
      queueCondition: 'short',
      cylinders: { '12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false },
      reportCount: 14,
      contactNumber: '+94 37 222 3456',
      notes: 'Delivery expected by 7 PM today.',
    },
  ];

  console.log(`Starting Firestore direct seed for ${stations.length} stations in project ${projectId}...`);

  for (const s of stations) {
    const cylinderFields = {};
    for (const [k, v] of Object.entries(s.cylinders)) {
      cylinderFields[k] = { booleanValue: v };
    }

    const docPayload = {
      fields: {
        name: { stringValue: s.name },
        brand: { stringValue: s.brand },
        address: { stringValue: s.address },
        town: { stringValue: s.town },
        latitude: { doubleValue: s.latitude },
        longitude: { doubleValue: s.longitude },
        status: { stringValue: s.status },
        queueCondition: { stringValue: s.queueCondition },
        cylinders: {
          mapValue: {
            fields: cylinderFields
          }
        },
        lastUpdated: { timestampValue: new Date().toISOString() },
        lastUpdatedBy: { stringValue: 'system_seed' },
        reportCount: { integerValue: s.reportCount.toString() },
        notes: { stringValue: s.notes },
        contactNumber: { stringValue: s.contactNumber },
      }
    };

    const url = `${baseUrl}/${s.id}`;
    const res = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(docPayload)
    });

    if (!res.ok) {
      const err = await res.text();
      console.error(`Failed to seed ${s.id}: ${res.status} - ${err}`);
    } else {
      console.log(`+ Seeded ${s.id} (${s.name})`);
    }
  }

  console.log('Finished seeding Firestore successfully!');
}

seed().catch(console.error);

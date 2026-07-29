import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const districtsData = [
  { name: 'Dhaka', nameBn: 'ঢাকা', division: 'Dhaka' },
  { name: 'Gazipur', nameBn: 'গাজীপুর', division: 'Dhaka' },
  { name: 'Narayanganj', nameBn: 'নারায়ণগঞ্জ', division: 'Dhaka' },
  { name: 'Tangail', nameBn: 'টাঙ্গাইল', division: 'Dhaka' },
  { name: 'Faridpur', nameBn: 'ফরিদপুর', division: 'Dhaka' },
  { name: 'Manikganj', nameBn: 'মানিকগঞ্জ', division: 'Dhaka' },
  { name: 'Munshiganj', nameBn: 'মুন্সীগঞ্জ', division: 'Dhaka' },
  { name: 'Narsingdi', nameBn: 'নরসিংদী', division: 'Dhaka' },
  { name: 'Rajbari', nameBn: 'রাজবাড়ী', division: 'Dhaka' },
  { name: 'Gopalganj', nameBn: 'গোপালগঞ্জ', division: 'Dhaka' },
  { name: 'Madaripur', nameBn: 'মাদারীপুর', division: 'Dhaka' },
  { name: 'Shariatpur', nameBn: 'শরীয়তপুর', division: 'Dhaka' },
  { name: 'Kishoreganj', nameBn: 'কিশোরগঞ্জ', division: 'Dhaka' },
  { name: 'Chattogram', nameBn: 'চট্টগ্রাম', division: 'Chattogram' },
  { name: 'Cox\'s Bazar', nameBn: 'কক্সবাজার', division: 'Chattogram' },
  { name: 'Cumilla', nameBn: 'কুমিল্লা', division: 'Chattogram' },
  { name: 'Feni', nameBn: 'ফেনী', division: 'Chattogram' },
  { name: 'Brahmanbaria', nameBn: 'ব্রাহ্মণবাড়িয়া', division: 'Chattogram' },
  { name: 'Noakhali', nameBn: 'নোয়াখালী', division: 'Chattogram' },
  { name: 'Chandpur', nameBn: 'চাঁদপুর', division: 'Chattogram' },
  { name: 'Lakshmipur', nameBn: 'লক্ষ্মীপুর', division: 'Chattogram' },
  { name: 'Rangamati', nameBn: 'রাঙ্গামাটি', division: 'Chattogram' },
  { name: 'Bandarban', nameBn: 'বান্দরবান', division: 'Chattogram' },
  { name: 'Khagrachhari', nameBn: 'খাগড়াছড়ি', division: 'Chattogram' },
  { name: 'Rajshahi', nameBn: 'রাজশাহী', division: 'Rajshahi' },
  { name: 'Bogra', nameBn: 'বগুড়া', division: 'Rajshahi' },
  { name: 'Pabna', nameBn: 'পাবনা', division: 'Rajshahi' },
  { name: 'Sirajganj', nameBn: 'সিরাজগঞ্জ', division: 'Rajshahi' },
  { name: 'Naogaon', nameBn: 'নওগাঁ', division: 'Rajshahi' },
  { name: 'Natore', nameBn: 'নাটোর', division: 'Rajshahi' },
  { name: 'Chapainawabganj', nameBn: 'চাঁপাইনবাবগঞ্জ', division: 'Rajshahi' },
  { name: 'Joypurhat', nameBn: 'জয়পুরহাট', division: 'Rajshahi' },
  { name: 'Khulna', nameBn: 'খুলনা', division: 'Khulna' },
  { name: 'Jashore', nameBn: 'যশোর', division: 'Khulna' },
  { name: 'Kushtia', nameBn: 'কুষ্টিয়া', division: 'Khulna' },
  { name: 'Satkhira', nameBn: 'সাতক্ষীরা', division: 'Khulna' },
  { name: 'Jhenaidah', nameBn: 'ঝিনাইদহ', division: 'Khulna' },
  { name: 'Bagerhat', nameBn: 'বাগেরহাট', division: 'Khulna' },
  { name: 'Chuadanga', nameBn: 'চুয়াডাঙ্গা', division: 'Khulna' },
  { name: 'Meherpur', nameBn: 'মেহেরপুর', division: 'Khulna' },
  { name: 'Narail', nameBn: 'নড়াইল', division: 'Khulna' },
  { name: 'Magura', nameBn: 'মাগুরা', division: 'Khulna' },
  { name: 'Barishal', nameBn: 'বরিশাল', division: 'Barishal' },
  { name: 'Patuakhali', nameBn: 'পটুয়াখালী', division: 'Barishal' },
  { name: 'Bhola', nameBn: 'ভোলা', division: 'Barishal' },
  { name: 'Pirojpur', nameBn: 'পিরোজপুর', division: 'Barishal' },
  { name: 'Barguna', nameBn: 'বরগুনা', division: 'Barishal' },
  { name: 'Jhalokati', nameBn: 'ঝালকাঠি', division: 'Barishal' },
  { name: 'Sylhet', nameBn: 'সিলেট', division: 'Sylhet' },
  { name: 'Moulvibazar', nameBn: 'মৌলভীবাজার', division: 'Sylhet' },
  { name: 'Habiganj', nameBn: 'হবিগঞ্জ', division: 'Sylhet' },
  { name: 'Sunamganj', nameBn: 'সুনামগঞ্জ', division: 'Sylhet' },
  { name: 'Rangpur', nameBn: 'রংপুর', division: 'Rangpur' },
  { name: 'Dinajpur', nameBn: 'দিনাজপুর', division: 'Rangpur' },
  { name: 'Gaibandha', nameBn: 'গাইবান্ধা', division: 'Rangpur' },
  { name: 'Kurigram', nameBn: 'কুড়িগ্রাম', division: 'Rangpur' },
  { name: 'Lalmonirhat', nameBn: 'লালমনিরহাট', division: 'Rangpur' },
  { name: 'Nilphamari', nameBn: 'নীলফামারী', division: 'Rangpur' },
  { name: 'Panchagarh', nameBn: 'পঞ্চগড়', division: 'Rangpur' },
  { name: 'Thakurgaon', nameBn: 'ঠাকুরগাঁও', division: 'Rangpur' },
  { name: 'Mymensingh', nameBn: 'ময়মনসিংহ', division: 'Mymensingh' },
  { name: 'Jamalpur', nameBn: 'জামালপুর', division: 'Mymensingh' },
  { name: 'Sherpur', nameBn: 'শেরপুর', division: 'Mymensingh' },
  { name: 'Netrokona', nameBn: 'নেত্রকোনা', division: 'Mymensingh' },
];

async function main() {
  console.log('Seeding districts to PostgreSQL database...');

  for (const district of districtsData) {
    await prisma.district.upsert({
      where: { name: district.name },
      update: {
        nameBn: district.nameBn,
        division: district.division,
      },
      create: {
        name: district.name,
        nameBn: district.nameBn,
        division: district.division,
      },
    });
  }

  console.log('Successfully seeded 64 Bangladesh districts into PostgreSQL database!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

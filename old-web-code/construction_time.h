// construction_time.h

#ifndef CONSTRUCTION_TIME_H
#define CONSTRUCTION_TIME_H

#include <ctime>
using namespace std;

class construction_time
{
public:
	construction_time();
	int second; 
	int minute;
	int hour;
	int day_of_the_month;
	int day_of_the_week;
	int month;
	int year;
};

construction_time::construction_time()
{
	const int EASTERN_DAYLIGHT_TIME = -4; // relative to GMT
	const int EASTERN_STANDARD_TIME = -5;
	const int SYSTEM_START_YEAR = 1970;
	const int SYSTEM_START_DAY_OF_THE_WEEK = 3;
	const int DAYS_PER_MONTH[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

	time_t seconds = time(0); // returns seconds since 00:00:00 on Jan 1, 1970
	second = seconds % 60;
	time_t minutes = seconds / 60;
	minute = minutes % 60;

	bool daylight_time = false;
	daylight_time_assumption_point:

	time_t hours = (minutes / 60) + (daylight_time? EASTERN_STANDARD_TIME : EASTERN_STANDARD_TIME);
	hour = hours % 24;
	time_t days = (hours / 24) + 1;
	day_of_the_week = (days + SYSTEM_START_DAY_OF_THE_WEEK) % 7;

	/* determine month and years, accounting for leap years
	 *
	 *   Feb has 29 days if:
	 *     (1) they year is evenly divisible by 4,
	 *     (2) but is not divisible by 100,
	 *     (3) except in the case of being also divisible by 400.
	 *   So 1972, 1976, 1980, 1984, 1988, 1992, 1996, and 2000 ARE leap years.
	 *   But 2100, 2200, and 2300 will NOT be leap years.
	 */
	time_t months = 0;
	year = SYSTEM_START_YEAR - 1;
	for (;;months++)
	{
		if (!(months % 12))
			year++;
		bool feb = ((months % 12) == 1);
		bool cond1 = ((year % 4) == 0);
		bool cond2 = (year % 100);
		bool cond3 = ((year % 400) == 0);
		if (feb && (cond3 || (cond1 && cond2))) {
			if (days <= 29)
				break;
			else
				days -= 29;
		}
		else {
			if (days <= DAYS_PER_MONTH[months % 12])
				break;
			else
				days -= DAYS_PER_MONTH[months % 12];
		}
	}

	month = months % 12;
	day_of_the_month = days;

	/* The United States follows daylight time between 2:00 a.m. on the second Sunday in March,
	 *   until 2:00 a.m. on the first Sunday in November.
	 */
	if (month == 2) { // March
		int dotw = day_of_the_week + (5 * 7);
		int sunday_count = 0;
		for (; days >= 0; days--)
			if (!(dotw-- % 7))
				sunday_count++;
		if (sunday_count >= 2) {
			daylight_time = true;
			goto daylight_time_assumption_point;
		}
	}
	else if (month == 10) { // November
		int dotw = day_of_the_week + (5 * 7);
		int sunday_count = 0;
		for (; days >= 0; days--)
			if (!(dotw-- % 7))
				sunday_count++;
		if (sunday_count < 1) {
			daylight_time = true;
			goto daylight_time_assumption_point;
		}
	}
	else if (2 < month && month < 10) { // definitely need to switch to daylight time
		daylight_time = true;
		goto daylight_time_assumption_point;
	}
}

#endif                                                                                                 

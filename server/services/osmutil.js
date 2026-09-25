//Unable to install: const openingHours = require('opening_hours');

/*
Possible properties values for POI types:

"opening_hours": "closed",
"description": "Aug. 2022 closed",
"operational_status": "closed",
"description": "This watertap is closed during winter",
"description": "Closed in winter",
 "opening_hours": "Mo-Th 11:30-20:30; Fr 11:30-21:00; Sa 10:00-21:00; Su closed",
 "opening_hours": "closed on public holidays",
 "opening_hours": "closed \"In der Regel verschlossen.\""
"seasonal": "yes"
 "drinking_water:seasonal": "no",
"drinking_water:seasonal": "false",
"seasonal": "no",
"seasonal": "spring;summer;autumn"
"seasonal": "summer"
"seasonal": "April-October",
*/


/**
 * Checks if a seasonal tag explicitly mentions month names or numeric month ranges.
 * @param {string} tag - e.g. "April-August", "Apr-Sep", "04-10", "summer", "yes"
 * @returns {boolean}
 */
function containsExplicitMonths(tag) {
  if (!tag || typeof tag !== 'string') return false;

  const clean = tag.trim().toLowerCase();

  // 1. Matches month names/abbreviations (jan, january, feb, etc.)
  const monthNameRegex = /\b(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|nov(ember)?|dec(ember)?)\b/i;
  
  if (monthNameRegex.test(clean)) {
    return true;
  }

  // 2. Matches numeric month ranges like "04-10", "4-10", "10-3"
  const numericRangeRegex = /^\s*(0?[1-9]|1[0-2])\s*[-–—]\s*(0?[1-9]|1[0-2])\s*$/;
  
  return numericRangeRegex.test(clean);
}

const MONTHS = {
  jan: 1, january: 1, feb: 2, february: 2, mar: 3, march: 3,
  apr: 4, april: 4, may: 5, jun: 6, june: 6, jul: 7, july: 7,
  aug: 8, august: 8, sep: 9, sept: 9, september: 9, oct: 10, october: 10,
  nov: 11, november: 11, dec: 12, december: 12
};

function parseMonth(str) {
  if (!str) return null;
  const clean = str.trim().toLowerCase();
  const num = parseInt(clean, 10);
  if (!isNaN(num) && num >= 1 && num <= 12) return num;
  return MONTHS[clean] || null;
}

function evaluateSeasonalTag(seasonalTag, checkDate = new Date()) {
  if (!seasonalTag) return { hasExplicitMonths: false, isOpen: true };

  const hasMonths = containsExplicitMonths(seasonalTag);

  if (!hasMonths) {
    // Return flag so calling code can handle "summer", "yes", etc. using hemisphere/winter logic
    return { hasExplicitMonths: false, isOpen: true };
  }

  // Extract and parse months
  const parts = seasonalTag.split(/[-–—]/);
  if (parts.length !== 2) {
    return { hasExplicitMonths: false, isOpen: true };
  }

  const startMonth = parseMonth(parts[0]);
  const endMonth = parseMonth(parts[1]);

  if (!startMonth || !endMonth) {
    return { hasExplicitMonths: false, isOpen: true };
  }

  const currentMonth = checkDate.getMonth() + 1; // 1-12

  let isOpen = false;
  if (startMonth <= endMonth) {
    isOpen = currentMonth >= startMonth && currentMonth <= endMonth;
  } else {
    // Cross-year range (e.g., Oct-Mar)
    isOpen = currentMonth >= startMonth || currentMonth <= endMonth;
  }

  return { hasExplicitMonths: true, isOpen: isOpen };
}

/*
TODO
Rule of thumb: Always prioritize explicit month/date ranges in tags like seasonal=April-October over location-based 
guesses. Use lat/lon as a fallback when the tag simply says seasonal=yes or description=closed in winter.
*/
function isWinterMonth(lat, monthIndex) {
    // monthIndex: 0 = Jan, 1 = Feb, ..., 11 = Dec
    if (lat >= 0) {
        // Northern Hemisphere: Dec, Jan, Feb, Mar
        return (monthIndex === 11 || monthIndex === 0 || monthIndex === 1 || monthIndex === 2);
    } else {
        // Southern Hemisphere: Jun, Jul, Aug, Sep
        return (monthIndex === 5 || monthIndex === 6 || monthIndex === 7 || monthIndex === 8);
    }
}
function isSeasonallyClosed(lat, currentDate = new Date()) {
    const month = currentDate.getMonth(); // 0-11
    const absLat = Math.abs(lat);

    // Tropics (between 23.5°N and 23.5°S): Ignore general winter freeze rules
    if (absLat < 23.5) {
        return false;
    }

    // Mid-to-high latitudes: Check hemisphere-specific winter freezing risk
    return isWinterMonth(lat, month);
}

function isOpeningHoursActive(openingHoursTag) {
    if (!openingHoursTag) return true; // Default to open if unspecified
    if (openingHoursTag.toLowerCase() === 'closed') return false;

    try {
        const oh = new openingHours(openingHoursTag);
        return oh.getState(); // returns true if open right now
    } catch (e) {
        // If the string contains "closed" anywhere, treat as closed; otherwise assume open
        return !openingHoursTag.toLowerCase().includes('closed');
    }
}

function isSimpleOpen(openingHoursTag, currentDate = new Date()) {
    if (!openingHoursTag) return true;
    
    const tag = openingHoursTag.trim().toLowerCase();
    
    // Hard closures
    if (tag === 'closed' || tag === 'off') return false;
    if (tag === '24/7' || tag === 'open') return true;

    // Check if current day is mentioned as 'closed' (e.g. "Su closed", "off")
    const days = ['su', 'mo', 'tu', 'we', 'th', 'fr', 'sa'];
    const currentDay = days[currentDate.getDay()];
    
    // Pattern like "su closed" or "su off"
    const dayClosedRegex = new RegExp(`\\b${currentDay}\\b[^;]*\\b(closed|off)\\b`, 'i');
    if (dayClosedRegex.test(tag)) {
        return false;
    }

    // Default to open if string is too complex to parse safely without full engine
    return true; 
}

function evaluateWaterPointStatus(tags, currentDate = new Date()) {
    const openingHours = tags['opening_hours']?.toLowerCase() || '';
    const operationalStatus = tags['operational_status']?.toLowerCase() || '';
    const seasonal = (tags['seasonal'] || tags['drinking_water:seasonal'] || '').toLowerCase();
    const description = (tags['description'] || tags['note'] || '').toLowerCase();

    // 1. Permanent / Hard Closures
    if (operationalStatus === 'closed' || operationalStatus === 'out_of_order' || operationalStatus === 'broken') {
        return { isAvailable: false, reason: 'Permanently or operationally closed' };
    }
    if (openingHours === 'closed') {
        return { isAvailable: false, reason: 'Marked closed' };
    }

    // 2. Text Keyword Catch (for informal notes)
    if (description.includes('permanently closed') || description.includes('defect') || description.includes('buiten werking')) {
        return { isAvailable: false, reason: 'Note indicates closure' };
    }

    // 3. Seasonal Checks
    const month = currentDate.getMonth() + 1; // 1-12
    const isWinterMonth = (month === 12 || month === 1 || month === 2 || month === 3);

    if (seasonal === 'yes' && isWinterMonth) {
        return { isAvailable: false, reason: 'Closed during winter season' };
    }
    if (description.includes('closed in winter') || description.includes('closed during winter') || description.includes('s winters gesloten')) {
        if (isWinterMonth) {
            return { isAvailable: false, reason: 'Closed in winter' };
        }
    }
    var seasonalCheck = evaluateSeasonalTag(seasonal, currentDate);
    if (seasonalCheck.hasExplicitMonths && !seasonalCheck.isOpen) {
        return { isAvailable: false, reason: 'Seasonally closed' };
    }

    // 4. Detailed opening_hours check (if present)
    // if (openingHours && !isOpeningHoursActive(tags['opening_hours'])) {
    if (openingHours && !isSimpleOpen(tags['opening_hours'], currentDate)) {
        return { isAvailable: false, reason: 'Outside opening hours' };
    }

    return { isAvailable: true, reason: 'Available' };
}

/*
Returns 1 if available, 0 if not available, based on properties of the POI.
*/
exports.isAvailable = function (properties) {
     if (!properties) {
        return 1;
    }
    const status = evaluateWaterPointStatus(properties);
    return status.isAvailable ? 1 : 0;
}

/*
Parsing properties to extract code values for POI types:
From geoJson file, exported from overapss-turbo.
Code values:

-1: not drinkable
0: neutral
1: drinking water
2: toilet
3: toilet and drinking water
*/
exports.extractCode = function (properties) {
    if (!properties) {
        return 0;
    }
    var code = 0;

    // "drinking_water"
    if (properties.amenity === "drinking_water") {
        code = 1;
        if (properties.drinking_water === "no") {
            code = -1;
        }        
        return code;
    }

    // "toilets"
    if (properties.amenity === "toilets") {
        code = 2;
        // "toilets with drinking_water"
        if (properties.drinking_water === "yes") {
            code = 3;
        }
        // No drinking water -> just a toilet        
        return code;
    }

    // "no drinking_water"
    if (properties.drinking_water === "no") {
        code = -1;
    }
    return code;
}
/**
 * Automatic metadata extraction from markdown chunks.
 * Extracts muscle groups, exercise names, difficulty tags, topic tags,
 * and structural information (section/subsection).
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Rich metadata attached to every chunk before embedding. */
export interface ChunkMetadata {
  source_file: string;
  category: string;
  section: string;
  subsection?: string;
  chunk_index: number;
  total_chunks: number;
  token_count: number;
  has_numbers: boolean;
  muscle_groups: string[];
  exercise_names: string[];
  difficulty_tags: string[];
  topic_tags: string[];
}

// ---------------------------------------------------------------------------
// Muscle group detection
// ---------------------------------------------------------------------------

/**
 * Canonical muscle group names that mirror the Flutter app's MuscleGroup enum.
 * Keys are the enum value names, values are regex-friendly display forms + aliases.
 */
const MUSCLE_GROUP_PATTERNS: Record<string, RegExp> = {
  chest:       /\b(chest|pectoral|pec)\b/i,
  back:        /\b(back|upper\s*back|mid[\s-]*back)\b/i,
  shoulders:   /\b(shoulder|delt(?:oid)?s?|anterior\s+delt|lateral\s+delt|posterior\s+delt|rear\s+delt)\b/i,
  biceps:      /\b(bicep|biceps|bi's)\b/i,
  triceps:     /\b(tricep|triceps|tri's)\b/i,
  forearms:    /\b(forearm|wrist\s+flexor|wrist\s+extensor|brachioradialis)\b/i,
  quadriceps:  /\b(quad(?:ricep)?s?|vastus|rectus\s+femoris)\b/i,
  hamstrings:  /\b(hamstring|ham(?:s|my)?|biceps?\s+femoris|semitendinosus|semimembranosus)\b/i,
  glutes:      /\b(glute|gluteus|gluteal|glutes|butt)\b/i,
  calves:      /\b(calf|calves|gastrocnemius|soleus)\b/i,
  core:        /\b(core|abdominal|abs|rectus\s+abdominis|transverse\s+abdominis)\b/i,
  traps:       /\b(trap(?:s|ezius)?)\b/i,
  lats:        /\b(lat(?:s|issimus)?(?:\s+dorsi)?)\b/i,
  obliques:    /\b(oblique|obliques|internal\s+oblique|external\s+oblique)\b/i,
  hipFlexors:  /\b(hip\s+flexor|iliopsoas|psoas)\b/i,
  adductors:   /\b(adductor|inner\s+thigh)\b/i,
  abductors:   /\b(abductor|gluteus\s+medius|outer\s+thigh)\b/i,
};

/**
 * Detect which muscle groups are mentioned in a text chunk.
 * @param text - The chunk text to scan.
 * @returns Array of MuscleGroup enum value names (e.g. ["chest", "triceps"]).
 */
export function extractMuscleGroups(text: string): string[] {
  const found: string[] = [];
  for (const [group, pattern] of Object.entries(MUSCLE_GROUP_PATTERNS)) {
    if (pattern.test(text)) {
      found.push(group);
    }
  }
  return found;
}

// ---------------------------------------------------------------------------
// Exercise name detection
// ---------------------------------------------------------------------------

/**
 * Known exercise names from the AlfaNutrition exercise database.
 * These are matched case-insensitively against chunk text.
 */
const KNOWN_EXERCISES: string[] = [
  "Barbell Bench Press", "Incline Dumbbell Press", "Cable Fly", "Push-Up", "Dips",
  "Barbell Row", "Pull-Up", "Lat Pulldown", "Seated Cable Row", "Dumbbell Row",
  "Overhead Press", "Lateral Raise", "Face Pull",
  "Barbell Curl", "Hammer Curl", "Tricep Pushdown", "Skull Crusher",
  "Barbell Squat", "Leg Press", "Leg Extension", "Walking Lunges",
  "Romanian Deadlift", "Lying Leg Curl", "Hip Thrust", "Standing Calf Raise",
  "Plank", "Cable Crunch", "Deadlift", "Barbell Shrug", "Wrist Curl",
  "Russian Twist", "Adductor Machine",
  "Decline Bench Press", "Cable Crossover", "Machine Chest Fly", "Diamond Push-Up",
  "T-Bar Row", "Chest-Supported Row", "Hyperextension", "Good Morning",
  "Meadows Row", "Straight-Arm Pulldown",
  "Dumbbell Overhead Press", "Arnold Press", "Cable Lateral Raise", "Rear Delt Fly",
  "Front Raise", "Upright Row",
  "Preacher Curl", "Concentration Curl", "Cable Curl", "Incline Dumbbell Curl",
  "EZ Bar Curl", "Spider Curl",
  "Overhead Tricep Extension", "Close-Grip Bench Press", "Tricep Kickback",
  "Cable Overhead Tricep Extension",
  "Front Squat", "Hack Squat", "Sissy Squat", "Step-Up", "Bulgarian Split Squat",
  "Nordic Hamstring Curl", "Stiff-Leg Deadlift", "Cable Pull-Through", "Seated Leg Curl",
  "Glute Bridge", "Cable Glute Kickback", "Sumo Deadlift", "Donkey Kick",
  "Seated Calf Raise", "Single-Leg Calf Raise", "Donkey Calf Raise",
  "Cable Woodchop", "Dead Bug", "Hanging Leg Raise", "Bicycle Crunch",
  "Pallof Press", "Ab Wheel Rollout",
  "Dumbbell Shrug", "Farmer's Walk",
  "Reverse Curl", "Reverse Wrist Curl",
  "Hip Abductor Machine", "Kettlebell Swing", "Trap Bar Deadlift",
  "Chin-Up", "Goblet Squat", "Landmine Press",
];

/** Pre-compiled exercise regexes for fast scanning. */
const EXERCISE_REGEXES: { name: string; re: RegExp }[] = KNOWN_EXERCISES.map((name) => ({
  name,
  re: new RegExp(`\\b${name.replace(/[-/()]/g, "\\$&")}\\b`, "i"),
}));

/**
 * Detect which known exercises are mentioned in a text chunk.
 * @param text - The chunk text to scan.
 * @returns Array of exercise name strings as they appear in the database.
 */
export function extractExerciseNames(text: string): string[] {
  const found: string[] = [];
  for (const { name, re } of EXERCISE_REGEXES) {
    if (re.test(text)) {
      found.push(name);
    }
  }
  return found;
}

// ---------------------------------------------------------------------------
// Difficulty tags
// ---------------------------------------------------------------------------

const DIFFICULTY_PATTERNS: { tag: string; re: RegExp }[] = [
  { tag: "beginner",     re: /\b(beginner|novice|starter|new\s+to|first[\s-]time|entry[\s-]level)\b/i },
  { tag: "intermediate", re: /\b(intermediate|moderate|some\s+experience)\b/i },
  { tag: "advanced",     re: /\b(advanced|expert|experienced|elite|competitive)\b/i },
];

/**
 * Extract difficulty-level tags from text.
 * @param text - The chunk text.
 * @returns Array of difficulty tag strings.
 */
export function extractDifficultyTags(text: string): string[] {
  const tags: string[] = [];
  for (const { tag, re } of DIFFICULTY_PATTERNS) {
    if (re.test(text)) tags.push(tag);
  }
  return tags;
}

// ---------------------------------------------------------------------------
// Topic tags
// ---------------------------------------------------------------------------

const TOPIC_PATTERNS: { tag: string; re: RegExp }[] = [
  { tag: "progressive_overload", re: /\bprogressive\s+overload\b/i },
  { tag: "hypertrophy",          re: /\bhypertrophy\b/i },
  { tag: "strength",             re: /\bstrength\s+(training|gain|program)\b/i },
  { tag: "endurance",            re: /\bendurance\b/i },
  { tag: "fat_loss",             re: /\b(fat\s+loss|cutting|caloric?\s+deficit|weight\s+loss)\b/i },
  { tag: "muscle_building",      re: /\b(muscle\s+build|bulking|mass\s+gain|lean\s+mass)\b/i },
  { tag: "nutrition",            re: /\b(nutrition|diet|macro|calorie|protein\s+intake|meal\s+plan)\b/i },
  { tag: "recovery",             re: /\b(recovery|rest\s+day|sleep|deload|overtraining)\b/i },
  { tag: "stretching",           re: /\b(stretch|flexibility|mobility|warm[\s-]?up|cool[\s-]?down)\b/i },
  { tag: "form",                 re: /\b(form|technique|proper\s+form|execution|cue)\b/i },
  { tag: "anatomy",              re: /\b(anatomy|muscle\s+fiber|insertion|origin|tendon|ligament)\b/i },
  { tag: "programming",          re: /\b(program|split|periodization|volume|frequency|training\s+plan)\b/i },
  { tag: "injury_prevention",    re: /\b(injury|prevent|rehab|prehab|pain|joint\s+health)\b/i },
  { tag: "cardio",               re: /\b(cardio|aerobic|hiit|liss|heart\s+rate|conditioning)\b/i },
  { tag: "supplements",          re: /\b(supplement|creatine|whey|bcaa|pre[\s-]?workout|vitamin)\b/i },
  { tag: "reps_sets",            re: /\b(\d+\s*(?:x|×)\s*\d+|sets?\s+(?:of|x)\s+\d+|rep\s+range)\b/i },
  { tag: "mind_muscle",          re: /\b(mind[\s-]muscle|contraction|squeeze|activation)\b/i },
];

/**
 * Extract topic tags from text based on keyword patterns.
 * @param text - The chunk text.
 * @returns Array of topic tag strings.
 */
export function extractTopicTags(text: string): string[] {
  const tags: string[] = [];
  for (const { tag, re } of TOPIC_PATTERNS) {
    if (re.test(text)) tags.push(tag);
  }
  return tags;
}

// ---------------------------------------------------------------------------
// Numeric content detection
// ---------------------------------------------------------------------------

/**
 * Detect whether a chunk contains specific numbers, percentages, or recommendations.
 * Useful for ranking chunks that contain concrete advice.
 * @param text - The chunk text.
 * @returns True if the chunk contains numeric recommendations.
 */
export function hasNumericContent(text: string): boolean {
  const patterns = [
    /\d+\s*[-–]\s*\d+\s*(reps?|sets?|minutes?|seconds?|grams?|mg|kcal|calories?|%)/i,
    /\d+\s*(g|mg|kcal|calories?)\s*(per|of|daily)/i,
    /\b\d{2,4}\s*(mg|g|kcal|IU)\b/i,
    /\b\d+(\.\d+)?\s*%/,
    /\b(1RM|one[\s-]rep\s+max)\b/i,
    /\bRPE\s*\d/i,
    /\b\d+\s*(x|×)\s*\d+/,
  ];
  return patterns.some((p) => p.test(text));
}

// ---------------------------------------------------------------------------
// Section/subsection extraction
// ---------------------------------------------------------------------------

/**
 * Determine the section and subsection for a chunk based on its position
 * relative to the document's heading structure.
 * @param fullDocument - The complete markdown document.
 * @param chunkStartOffset - Character offset where the chunk starts.
 * @returns Object with section and optional subsection strings.
 */
export function extractSectionInfo(
  fullDocument: string,
  chunkStartOffset: number,
): { section: string; subsection?: string } {
  const textBefore = fullDocument.slice(0, chunkStartOffset);
  const lines = textBefore.split("\n");

  let section = "Introduction";
  let subsection: string | undefined;

  for (const line of lines) {
    const h1 = line.match(/^#\s+(.*)/);
    const h2 = line.match(/^##\s+(.*)/);
    const h3 = line.match(/^###\s+(.*)/);

    if (h1) {
      section = h1[1].trim();
      subsection = undefined;
    } else if (h2) {
      section = h2[1].trim();
      subsection = undefined;
    } else if (h3) {
      subsection = h3[1].trim();
    }
  }

  return { section, subsection };
}

// ---------------------------------------------------------------------------
// Combined extractor
// ---------------------------------------------------------------------------

/**
 * Build complete ChunkMetadata for a single chunk.
 * @param text - The chunk text.
 * @param fullDocument - The complete source document.
 * @param chunkStartOffset - Character offset of the chunk within the full document.
 * @param sourceFile - Filename without extension.
 * @param category - Document category slug.
 * @param chunkIndex - 0-based index of this chunk within the file.
 * @param totalChunks - Total number of chunks in the file.
 * @param tokenCount - Pre-computed token count for this chunk.
 * @returns Complete ChunkMetadata object.
 */
export function buildChunkMetadata(
  text: string,
  fullDocument: string,
  chunkStartOffset: number,
  sourceFile: string,
  category: string,
  chunkIndex: number,
  totalChunks: number,
  tokenCount: number,
): ChunkMetadata {
  const { section, subsection } = extractSectionInfo(fullDocument, chunkStartOffset);

  return {
    source_file: sourceFile,
    category,
    section,
    subsection,
    chunk_index: chunkIndex,
    total_chunks: totalChunks,
    token_count: tokenCount,
    has_numbers: hasNumericContent(text),
    muscle_groups: extractMuscleGroups(text),
    exercise_names: extractExerciseNames(text),
    difficulty_tags: extractDifficultyTags(text),
    topic_tags: extractTopicTags(text),
  };
}

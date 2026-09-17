export interface Content {
  id: number;
  name: string;
  title?: string;
  text_content?: string;
  attachments?: any[];
  external_url?: any[];
  assessments?: any[];
  sort_order?: number;
  is_active?: boolean;
}

export interface Chapter {
  id: number;
  name: string;
  contents: Content[];
  assessments?: any[];
  is_expanded?: boolean;
}

export interface Level {
  id: number;
  name: string;
  code?: string;
  chapters: Chapter[];
  is_expanded?: boolean;
}

export interface CourseStructure {
  id: number;
  name: string;
  description?: string;
  levels: Level[];
}

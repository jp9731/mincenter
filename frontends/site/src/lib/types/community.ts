export interface Post {
  id: string;
  title: string;
  content: string;
  author: {
    id: string;
    name: string;
    avatar?: string;
  };
  category: string;
  tags: string[];
  likes: number;
  comments: number;
  views: number;
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  id: string;
  content: string;
  author: {
    id: string;
    name: string;
    avatar?: string;
  };
  postId: string;
  parentId?: string;
  likes: number;
  createdAt: string;
  updatedAt: string;
}

export interface Category {
  id: string;
  name: string;
  description: string;
  postCount: number;
}

export interface Tag {
  id: string;
  name: string;
  postCount: number;
}

export type PostSortOption = 'latest' | 'popular' | 'comments';
export type PostFilter = {
  category?: string;
  tags?: string[];
  search?: string;
  sort: PostSortOption;
};
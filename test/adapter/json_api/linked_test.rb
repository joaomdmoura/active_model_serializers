require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class LinkedTest < Minitest::Test
          def setup
            @author1 = Author.new(id: 1, name: 'Steve K.')
            @author2 = Author.new(id: 2, name: 'Tenderlove')
            @bio1 = Bio.new(id: 1, content: 'AMS Contributor')
            @bio2 = Bio.new(id: 2, content: 'Rails Contributor')
            @first_post = Post.new(id: 10, title: 'Hello!!', body: 'Hello, world!!')
            @second_post = Post.new(id: 20, title: 'New Post', body: 'Body')
            @third_post = Post.new(id: 30, title: 'Yet Another Post', body: 'Body')
            @blog = Blog.new({ name: 'AMS Blog' })
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
            @first_post.blog = @blog
            @second_post.blog = @blog
            @third_post.blog = nil
            @first_post.comments = [@first_comment, @second_comment]
            @second_post.comments = []
            @third_post.comments = []
            @first_post.author = @author1
            @second_post.author = @author2
            @third_post.author = @author1
            @first_comment.post = @first_post
            @first_comment.author = nil
            @second_comment.post = @first_post
            @second_comment.author = nil
            @author1.posts = [@first_post, @third_post]
            @author1.bio = @bio1
            @author1.roles = []
            @author2.posts = [@second_post]
            @author2.bio = @bio2
            @author2.roles = []
            @bio1.author = @author1
            @bio2.author = @author2
          end

          def test_include_multiple_posts_and_linked
            serializer = ArraySerializer.new([@first_post, @second_post])
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer,
              include: ['author', 'author.bio', 'comments']
            )
            alt_adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer,
              include: 'author,author.bio,comments'
            )

            expected = {
              linked: {
                comments: [
                  {
                    id: "1",
                    body: "ZOMG A COMMENT",
                    links: {
                      post: "1",
                      author: nil
                    }
                  }, {
                    id: "2",
                    body: "ZOMG ANOTHER COMMENT",
                    links: {
                      post: "1",
                      author: nil
                    }
                  }
                ],
                authors: [
                  {
                    id: "1",
                    name: "Steve K.",
                    links: {
                      posts: ["1", "3"],
                      roles: [],
                      bio: "1"
                    }
                  }, {
                    id: "2",
                    name: "Tenderlove",
                    links: {
                      posts: ["2"],
                      roles: [],
                      bio: "2"
                    }
                  }
                ],
                bios: [
                  {
                    id: "1",
                    content: "AMS Contributor",
                    links: {
                      author: "1"
                    }
                  }, {
                    id: "2",
                    content: "Rails Contributor",
                    links: {
                      author: "2"
                    }
                  }
                ]
              },
              posts: [
                {
                  id: "10",
                  title: "Hello!!",
                  body: "Hello, world!!",
                  links: {
                    comments: ['1', '2'],
                    blog: "999",
                    author: "1"
                  }
                },
                {
                  id: "2",
                  title: "New Post",
                  body: "Body",
                  links: {
                    comments: [],
                    blog: "999",
                    author: "2"
                  }
                }
              ]
            }
            assert_equal expected, adapter.serializable_hash
            assert_equal expected, alt_adapter.serializable_hash
          end

          def test_include_multiple_posts_and_linked
            serializer = BioSerializer.new @bio1
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer,
              include: ['author', 'author.posts']
            )
            alt_adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer,
              include: 'author,author.posts'
            )

            expected = {
              authors: [
                {
                  id: "1",
                  name: "Steve K.",
                  links: {
                    posts: ["10", "30"],
                    roles: [],
                    bio: "1"
                  }
                }
              ],
              posts: [
                {
                  id: "10",
                  title: "Hello!!",
                  body: "Hello, world!!",
                  links: {
                    comments: ["1", "2"],
                    blog: "999",
                    author: "1"
                  }
                }, {
                  id: "30",
                  title: "Yet Another Post",
                  body: "Body",
                  links: {
                    comments: [],
                    blog: "999",
                    author: "1"
                  }
                }
              ]
            }
            assert_equal expected, adapter.serializable_hash[:linked]
            assert_equal expected, alt_adapter.serializable_hash[:linked]
          end

          def test_ignore_model_namespace_for_linked_resource_type
            spammy_post = Post.new(id: 123)
            spammy_post.related = [Spam::UnrelatedLink.new(id: 456)]
            serializer = SpammyPostSerializer.new(spammy_post)
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer)
            links = adapter.serializable_hash[:posts][:links]
            expected = {
              related: {
                type: 'unrelated_links',
                ids: ['456']
              }
            }
            assert_equal expected, links
          end
        end
      end
    end
  end
end

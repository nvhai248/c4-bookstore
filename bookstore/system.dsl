workspace extends ../system-catalog.dsl {
    name "Bookstore Platform"
    description "Internet bookstore platform"
    model {
        !extend bookstoreSystem {
             # Level 2: Containers
            # <variable> = container <name> <description> <technology> <tag>
            searchWebApi = container "Search Web API" "Allows only authorized users searching books records via HTTPS API" "Go"
            adminWebApi = container "Admin Web API" "Allows only authorized users administering books details via HTTPS API" "Go" {
                # Level 3: Components
                # <variable> = component <name> <description> <technology> <tag>
                bookService = component "Book Service" "Allows administrating book details" "Go"
                authService = component "Authorizer" "Authorize users by using external Authorization System" "Go"
                bookEventPublisher = component "Book Events Publisher" "Publishes books-related events to Events Publisher" "Go"
            }
            publicWebApi = container "Public Web API" "Allows public users getting books information" "Go"
            searchDatabase = container "Search Database" "Stores searchable book information" "ElasticSearch" "Database"
            bookstoreDatabase = container "Bookstore Database" "Stores book details" "PostgreSQL" "Database"
            bookEventStream = container "Book Event Stream" "Handles book-related domain events" "Apache Kafka 3.0"
            bookEventConsumer = container "Book Event Consumer" "Listening to domain events and write publisher to Search Database for updating" "Go"
            publisherRecurrentUpdater = container "Publisher Recurrent Updater" "Listening to external events from Publisher System, and update book information" "Go"
        }

        # Relationship between Containers
        publicUser -> publicWebApi "View book information" "JSON/HTTPS"
        publicWebApi -> searchDatabase "Retrieve book search data" "ODBC"
        authorizedUser -> searchWebApi "Search book with more details" "JSON/HTTPS"
        searchWebApi -> authSystem "Authorize user" "JSON/HTTPS"
        searchWebApi -> searchDatabase "Retrieve book search data" "ODBC"
        authorizedUser -> adminWebApi "Administrate books and their details" "JSON/HTTPS"
        adminWebApi -> authSystem "Authorize user" "JSON/HTTPS"
        adminWebApi -> bookstoreDatabase "Reads/Write book detail data" "ODBC"
        adminWebApi -> bookEventStream "Publish book update events" {
            tags "Async Request"
        }
        bookEventStream -> bookEventConsumer "Consume book update events"
        bookEventConsumer -> searchDatabase "Write book search data" "ODBC"
        publisherRecurrentUpdater -> adminWebApi "Makes API calls to" "JSON/HTTPS"

        # Relationship between Containers and External System
        publisherSystem -> publisherRecurrentUpdater "Consume book publication update events" {
            tags "Async Request"
        }

        # Relationship between Components
        authorizedUser -> bookService "Administrate book details" "JSON/HTTPS"
        publisherRecurrentUpdater -> bookService "Makes API calls to" "JSON/HTTPS"
        bookService -> authService "Uses"
        bookService -> bookEventPublisher "Uses"

        # Relationship between Components and Other Containers
        authService -> authSystem "Authorize user permissions" "JSON/HTTPS"
        bookService -> bookstoreDatabase "Read/Write data" "ODBC"
        bookEventPublisher -> bookEventStream "Publish book update events"

        developer = person "Developer" "Internal bookstore platform developer" "User"

        deployWorkflow = softwareSystem "CI/CD Workflow" "Workflow CI/CD for deploying system using AWS Services" "Target System" {
            repository = container "Code Repository" "" "Github"
            pipeline = container "CodePipeline" {
                tags "Amazon Web Services - CodePipeline" "Dynamic Element"
            }
            codeBuilder = container "CodeBuild" "" {
                tags "Amazon Web Services - CodeBuild" "Dynamic Element"
            }
            containerRegistry = container "Amazon ECR" {
                tags "Amazon Web Services - EC2 Container Registry" "Dynamic Element"
            }
            cluster = container "Amazon EKS" {
                tags "Amazon Web Services - Elastic Kubernetes Service" "Dynamic Element"
            }
        }

        developer -> repository
        repository -> pipeline
        pipeline -> codeBuilder
        codeBuilder -> containerRegistry
        codeBuilder -> pipeline
        pipeline -> cluster
    }
    views {
        # Level 1
        systemContext bookstoreSystem "SystemContext" {
            include *
            # default: tb,
            # support tb, bt, lr, rl
            autoLayout lr
        }
        # Level 2
        container bookstoreSystem "Containers" {
            include *
            autoLayout lr
        }
        # Level 3
        component adminWebApi "Components" {
            include *
            autoLayout lr
        }
        # Dynamic <container> <name> <description>
        dynamic deployWorkflow "Dynamic-001-WF" "Bookstore platform deployment workflow" {
            developer -> repository "Commit, and push changes"
            repository -> pipeline "Trigger pipeline job"
            pipeline -> codeBuilder "Download source code, and start build process"
            codeBuilder -> containerRegistry "Upload Docker image with unique tag"
            codeBuilder -> pipeline "Return the build result"
            pipeline -> cluster "Deploy container"
            autoLayout lr
        }
        
        theme default
    }
}